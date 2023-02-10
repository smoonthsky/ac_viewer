package anonymity.ac.viewer.channel.streams

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DecodeFormat
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.RequestOptions
import anonymity.ac.viewer.decoder.MultiTrackImage
import anonymity.ac.viewer.decoder.TiffImage
import anonymity.ac.viewer.decoder.VideoThumbnail
import anonymity.ac.viewer.utils.BitmapUtils.applyExifOrientation
import anonymity.ac.viewer.utils.BitmapUtils.getBytes
import anonymity.ac.viewer.utils.LogUtils
import anonymity.ac.viewer.utils.MemoryUtils
import anonymity.ac.viewer.utils.MimeTypes
import anonymity.ac.viewer.utils.MimeTypes.canDecodeWithFlutter
import anonymity.ac.viewer.utils.MimeTypes.isHeic
import anonymity.ac.viewer.utils.MimeTypes.isVideo
import anonymity.ac.viewer.utils.MimeTypes.needRotationAfterGlide
import anonymity.ac.viewer.utils.StorageUtils
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.io.InputStream

class ImageByteStreamHandler(private val context: Context, private val arguments: Any?) : EventChannel.StreamHandler {
    private val ioScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var eventSink: EventSink
    private lateinit var handler: Handler

    override fun onListen(args: Any, eventSink: EventSink) {
        this.eventSink = eventSink
        handler = Handler(Looper.getMainLooper())

        ioScope.launch { streamImage() }
    }

    override fun onCancel(o: Any) {}

    private fun success(bytes: ByteArray?) {
        handler.post {
            try {
                eventSink.success(bytes)
            } catch (e: Exception) {
                Log.w(LOG_TAG, "failed to use event sink", e)
            }
        }
    }

    private fun error(errorCode: String, errorMessage: String, errorDetails: Any?) {
        handler.post {
            try {
                eventSink.error(errorCode, errorMessage, errorDetails)
            } catch (e: Exception) {
                Log.w(LOG_TAG, "failed to use event sink", e)
            }
        }
    }

    private fun endOfStream() {
        handler.post {
            try {
                eventSink.endOfStream()
            } catch (e: Exception) {
                Log.w(LOG_TAG, "failed to use event sink", e)
            }
        }
    }

    // Supported image formats:
    // - Flutter (as of v1.20): JPEG, PNG, GIF, Animated GIF, WebP, Animated WebP, BMP, and WBMP
    // - Android: https://developer.android.com/guide/topics/media/media-formats#image-formats
    // - Glide: https://github.com/bumptech/glide/blob/master/library/src/main/java/com/bumptech/glide/load/ImageHeaderParser.java
    private suspend fun streamImage() {
        if (arguments !is Map<*, *>) {
            endOfStream()
            return
        }

        val mimeType = arguments["mimeType"] as String?
        val uri = (arguments["uri"] as String?)?.let { Uri.parse(it) }
        val sizeBytes = (arguments["sizeBytes"] as Number?)?.toLong()
        val rotationDegrees = arguments["rotationDegrees"] as Int
        val isFlipped = arguments["isFlipped"] as Boolean
        val pageId = arguments["pageId"] as Int?

        if (mimeType == null || uri == null) {
            error("streamImage-args", "missing arguments", null)
            endOfStream()
            return
        }

        if (isVideo(mimeType)) {
            streamVideoByGlide(uri, mimeType, sizeBytes)
        } else if (!canDecodeWithFlutter(mimeType, rotationDegrees, isFlipped)) {
            // decode exotic format on platform side, then encode it in portable format for Flutter
            streamImageByGlide(uri, pageId, mimeType, sizeBytes, rotationDegrees, isFlipped)
        } else {
            // to be decoded by Flutter
            streamImageAsIs(uri, mimeType, sizeBytes)
        }
        endOfStream()
    }

    private fun streamImageAsIs(uri: Uri, mimeType: String, sizeBytes: Long?) {
        if (!MemoryUtils.canAllocate(sizeBytes)) {
            error("streamImage-image-read-large", "original image too large at $sizeBytes bytes, for mimeType=$mimeType uri=$uri", null)
            return
        }

        try {
            StorageUtils.openInputStream(context, uri)?.use { input -> streamBytes(input) }
        } catch (e: Exception) {
            error("streamImage-image-read-exception", "failed to get image for mimeType=$mimeType uri=$uri", e.message)
        }
    }

    private suspend fun streamImageByGlide(
        uri: Uri,
        pageId: Int?,
        mimeType: String,
        sizeBytes: Long?,
        rotationDegrees: Int,
        isFlipped: Boolean,
    ) {
        val model: Any = if (isHeic(mimeType) && pageId != null) {
            MultiTrackImage(context, uri, pageId)
        } else if (mimeType == MimeTypes.TIFF) {
            TiffImage(context, uri, pageId)
        } else {
            StorageUtils.getGlideSafeUri(context, uri, mimeType, sizeBytes)
        }

        val target = Glide.with(context)
            .asBitmap()
            .apply(glideOptions)
            .load(model)
            .submit()
        try {
            @Suppress("BlockingMethodInNonBlockingContext")
            var bitmap = target.get()
            if (needRotationAfterGlide(mimeType)) {
                bitmap = applyExifOrientation(context, bitmap, rotationDegrees, isFlipped)
            }
            if (bitmap != null) {
                val bytes = bitmap.getBytes(MimeTypes.canHaveAlpha(mimeType), recycle = false)
                if (MemoryUtils.canAllocate(sizeBytes)) {
                    success(bytes)
                } else {
                    error("streamImage-image-decode-large", "decoded image too large at $sizeBytes bytes, for mimeType=$mimeType uri=$uri", null)
                }
            } else {
                error("streamImage-image-decode-null", "failed to get image for mimeType=$mimeType uri=$uri", null)
            }
        } catch (e: Exception) {
            error("streamImage-image-decode-exception", "failed to get image for mimeType=$mimeType uri=$uri model=$model", toErrorDetails(e))
        } finally {
            Glide.with(context).clear(target)
        }
    }

    private suspend fun streamVideoByGlide(uri: Uri, mimeType: String, sizeBytes: Long?) {
        val target = Glide.with(context)
            .asBitmap()
            .apply(glideOptions)
            .load(VideoThumbnail(context, uri))
            .submit()
        try {
            @Suppress("BlockingMethodInNonBlockingContext")
            val bitmap = target.get()
            if (bitmap != null) {
                val bytes = bitmap.getBytes(canHaveAlpha = false, recycle = false)
                if (MemoryUtils.canAllocate(sizeBytes)) {
                    success(bytes)
                } else {
                    error("streamImage-video-large", "decoded image too large at $sizeBytes bytes, for mimeType=$mimeType uri=$uri", null)
                }
            } else {
                error("streamImage-video-null", "failed to get image for mimeType=$mimeType uri=$uri", null)
            }
        } catch (e: Exception) {
            error("streamImage-video-exception", "failed to get image for mimeType=$mimeType uri=$uri", e.message)
        } finally {
            Glide.with(context).clear(target)
        }
    }

    private fun toErrorDetails(e: Exception): String? {
        val errorDetails = e.message
        return if (errorDetails?.isNotEmpty() == true) {
            errorDetails.split(Regex("\n"), 2).first()
        } else {
            errorDetails
        }
    }

    private fun streamBytes(inputStream: InputStream) {
        val buffer = ByteArray(BUFFER_SIZE)
        var len: Int
        while (inputStream.read(buffer).also { len = it } != -1) {
            // cannot decode image on Flutter side when using `buffer` directly
            success(buffer.copyOf(len))
        }
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ImageByteStreamHandler>()
        const val CHANNEL = "deckers.thibault/aves/media_byte_stream"

        private const val BUFFER_SIZE = 2 shl 17 // 256kB

        // request a fresh image with the highest quality format
        private val glideOptions = RequestOptions()
            .format(DecodeFormat.PREFER_ARGB_8888)
            .diskCacheStrategy(DiskCacheStrategy.NONE)
            .skipMemoryCache(true)
    }
}