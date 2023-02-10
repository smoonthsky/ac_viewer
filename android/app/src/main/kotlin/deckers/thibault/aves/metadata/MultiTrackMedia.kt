package anonymity.ac.viewer.metadata

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import anonymity.ac.viewer.utils.LogUtils
import anonymity.ac.viewer.utils.MimeTypes
import anonymity.ac.viewer.utils.StorageUtils

object MultiTrackMedia {
    private val LOG_TAG = LogUtils.createTag<MultiTrackMedia>()

    @RequiresApi(Build.VERSION_CODES.P)
    fun getImage(context: Context, uri: Uri, trackIndex: Int?): Bitmap? {
        val retriever = StorageUtils.openMetadataRetriever(context, uri) ?: return null
        try {
            return if (trackIndex != null) {
                val imageIndex = trackIndexToImageIndex(context, uri, trackIndex) ?: return null
                retriever.getImageAtIndex(imageIndex)
            } else {
                retriever.primaryImage
            }
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to extract image from uri=$uri trackIndex=$trackIndex", e)
        } finally {
            // cannot rely on `MediaMetadataRetriever` being `AutoCloseable` on older APIs
            retriever.release()
        }
        return null
    }

    private fun trackIndexToImageIndex(context: Context, uri: Uri, trackIndex: Int): Int? {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(context, uri, null)
            val trackCount = extractor.trackCount
            var imageIndex = 0
            for (i in 0 until trackCount) {
                val trackFormat = extractor.getTrackFormat(i)
                if (trackIndex == i) {
                    return imageIndex
                }
                if (MimeTypes.isImage(trackFormat.getString(MediaFormat.KEY_MIME))) {
                    imageIndex++
                }
            }
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to get image index for uri=$uri, trackIndex=$trackIndex", e)
        } finally {
            extractor.release()
        }
        return null
    }
}