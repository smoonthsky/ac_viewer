package anonymity.ac.viewer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import app.loup.streams_channel.StreamsChannel
import anonymity.ac.viewer.channel.AvesByteSendingMethodCodec
import anonymity.ac.viewer.channel.calls.*
import anonymity.ac.viewer.channel.streams.ImageByteStreamHandler
import anonymity.ac.viewer.channel.streams.MediaStoreStreamHandler
import anonymity.ac.viewer.utils.FlutterUtils
import anonymity.ac.viewer.utils.LogUtils
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.nio.ByteBuffer
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import kotlin.math.roundToInt

import android.app.AlarmManager
import android.os.SystemClock
import android.content.ComponentName

class HomeWidgetProvider : AppWidgetProvider() {
    private val defaultScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        // Check if the intent action is the correct one
        if (Intent.ACTION_BOOT_COMPLETED == intent?.action) {
            // Perform the widget update here
            AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context!!, HomeWidgetProvider::class.java)).also { appWidgetIds ->
                for (widgetId in appWidgetIds) {
                    defaultScope.launch {
                        onUpdate(context, AppWidgetManager.getInstance(context), intArrayOf(widgetId))
                    }
                }
            }
        }
    }


    private suspend fun scheduleNextUpdate(context: Context, widgetId: Int) {
        Log.d(LOG_TAG, "Widget scheduleNextUpdate start  widgetId==$widgetId")
        initFlutterEngine(context)
        val messenger = flutterEngine!!.dartExecutor
        val channel = MethodChannel(messenger, WIDGET_DRAW_CHANNEL)
        //var internalFromWidget = 0
        var internal = 0
        try {
            val internalFromWidget = suspendCoroutine { cont ->
                defaultScope.launch {
                    FlutterUtils.runOnUiThread {
                        channel.invokeMethod("getWidgetUpdateInterval", widgetId, object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                cont.resume(result)
                            }

                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                cont.resumeWithException(Exception("$errorCode: $errorMessage\n$errorDetails"))
                            }

                            override fun notImplemented() {
                                cont.resumeWithException(Exception("not implemented"))
                            }
                        })
                    }
                }
            }
            if (internalFromWidget is Int) {
                internal = internalFromWidget * 1000
                Log.e(LOG_TAG, " scheduleNextUpdate get widget update interval for widgetId=$widgetId , internalFromWidget")
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "scheduleNextUpdate failed to get widget update interval for widgetId=$widgetId , $e")
        }
        // Log.d(LOG_TAG, "Widget scheduleNextUpdate get result $internal widgetId==$widgetId")
        if (internal <= 0) internal = 10 * 1000
        val list = listOf(widgetId)
        val appWidgetIds = list.toIntArray()
        val alarmManager: AlarmManager by lazy {
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        }
        val intent = Intent(context, HomeWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        }
        val pendingIntent = PendingIntent.getBroadcast(context, widgetId, intent, PendingIntent.FLAG_UPDATE_CURRENT)
//Even though a new Intent object is created every time scheduleNextUpdate is called,
//the PendingIntent that is created from it will overwrite the previous one because it has the same widgetId as the request code.
//This is because the PendingIntent uses the widgetId as the request code to identify it and associate it with a widget.
//When a new PendingIntent is created with the same widgetId,
// the system considers it to be a new request to update the same widget and replaces the previous PendingIntent with the new one.
//This behavior is by design and is used to ensure that the correct widget is updated
// and that the previous scheduled updates are replaced with the new ones.
        alarmManager.setInexactRepeating(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + internal, internal.toLong(), pendingIntent)
        //alarmManager.setExact(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + internal, pendingIntent)
        Log.d(LOG_TAG, "Widget scheduleNextUpdate end  widgetId==$widgetId")

    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(LOG_TAG, "Widget onUpdate test widgetIds=${appWidgetIds.contentToString()}")

        for (widgetId in appWidgetIds) {
            val widgetInfo = appWidgetManager.getAppWidgetOptions(widgetId)

            defaultScope.launch {
                val backgroundBytes = getBytes(context, widgetId, widgetInfo, drawEntryImage = false)
                updateWidgetImage(context, appWidgetManager, widgetId, widgetInfo, backgroundBytes)

                val imageBytes = getBytes(context, widgetId, widgetInfo, drawEntryImage = true, reuseEntry = false)
                updateWidgetImage(context, appWidgetManager, widgetId, widgetInfo, imageBytes)

                scheduleNextUpdate(context,widgetId)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager?, widgetId: Int, widgetInfo: Bundle?) {
        //Log.d(LOG_TAG, "Widget onAppWidgetOptionsChanged widgetId=$widgetId")
        appWidgetManager ?: return
        widgetInfo ?: return

        if (imageByteFetchJob != null) {
            imageByteFetchJob?.cancel()
        }
        imageByteFetchJob = defaultScope.launch {
            delay(500)
            val imageBytes = getBytes(context, widgetId, widgetInfo, drawEntryImage = true, reuseEntry = true)
            updateWidgetImage(context, appWidgetManager, widgetId, widgetInfo, imageBytes)
            // do put this method after onAppWidgetOptionsChanged, for that ,it can get the setting internal not default internal
            scheduleNextUpdate(context,widgetId)
        }
    }

    private fun getDevicePixelRatio(): Float = Resources.getSystem().displayMetrics.density

    private fun getWidgetSizePx(context: Context, widgetInfo: Bundle): Pair<Int, Int> {
        val devicePixelRatio = getDevicePixelRatio()
        val isPortrait = context.resources.configuration.orientation == Configuration.ORIENTATION_PORTRAIT
        val widthKey = if (isPortrait) AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH
        val heightKey = if (isPortrait) AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
        val widthPx = (widgetInfo.getInt(widthKey) * devicePixelRatio).roundToInt()
        val heightPx = (widgetInfo.getInt(heightKey) * devicePixelRatio).roundToInt()
        return Pair(widthPx, heightPx)
    }

    private suspend fun getBytes(
        context: Context,
        widgetId: Int,
        widgetInfo: Bundle,
        drawEntryImage: Boolean,
        reuseEntry: Boolean = false,
    ): ByteArray? {
        val (widthPx, heightPx) = getWidgetSizePx(context, widgetInfo)
        if (widthPx == 0 || heightPx == 0) return null

        initFlutterEngine(context)
        val messenger = flutterEngine!!.dartExecutor
        val channel = MethodChannel(messenger, WIDGET_DRAW_CHANNEL)
        try {
            val bytes = suspendCoroutine { cont ->
                defaultScope.launch {
                    FlutterUtils.runOnUiThread {
                        channel.invokeMethod("drawWidget", hashMapOf(
                            "widgetId" to widgetId,
                            "widthPx" to widthPx,
                            "heightPx" to heightPx,
                            "devicePixelRatio" to getDevicePixelRatio(),
                            "drawEntryImage" to drawEntryImage,
                            "reuseEntry" to reuseEntry,
                        ), object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                cont.resume(result)
                            }

                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                cont.resumeWithException(Exception("$errorCode: $errorMessage\n$errorDetails"))
                            }

                            override fun notImplemented() {
                                cont.resumeWithException(Exception("not implemented"))
                            }
                        })
                    }
                }
            }
            if (bytes is ByteArray) return bytes
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to draw widget for widgetId=$widgetId widthPx=$widthPx heightPx=$heightPx", e)
        }
        return null
    }

    private fun updateWidgetImage(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetInfo: Bundle,
        bytes: ByteArray?,
    ) {
        bytes ?: return
        Log.d(LOG_TAG, "Widget updateWidgetImage  widgetId=$widgetId")
        val (widthPx, heightPx) = getWidgetSizePx(context, widgetInfo)
        if (widthPx == 0 || heightPx == 0) return

        try {
            val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(bytes))

            // set a unique URI to prevent the intent (and its extras) from being shared by different widgets
            val intent = Intent(MainActivity.INTENT_ACTION_WIDGET_OPEN, Uri.parse("widget://$widgetId"), context, MainActivity::class.java)
                .putExtra(MainActivity.EXTRA_KEY_WIDGET_ID, widgetId)

            val activity = PendingIntent.getActivity(
                context,
                0,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )

            val views = RemoteViews(context.packageName, R.layout.app_widget).apply {
                setImageViewBitmap(R.id.widget_img, bitmap)
                setOnClickPendingIntent(R.id.widget_img, activity)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
            bitmap.recycle()
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to draw widget", e)
        }
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<HomeWidgetProvider>()
        private const val WIDGET_DART_ENTRYPOINT = "widgetMain"
        private const val WIDGET_DRAW_CHANNEL = "deckers.thibault/aves/widget_draw"

        private var flutterEngine: FlutterEngine? = null
        private var imageByteFetchJob: Job? = null

        private suspend fun initFlutterEngine(context: Context) {
            if (flutterEngine != null) return

            FlutterUtils.runOnUiThread {
                flutterEngine = FlutterEngine(context.applicationContext)
            }
            initChannels(context)

            flutterEngine!!.apply {
                if (!dartExecutor.isExecutingDart) {
                    val appBundlePathOverride = FlutterInjector.instance().flutterLoader().findAppBundlePath()
                    val entrypoint = DartExecutor.DartEntrypoint(appBundlePathOverride, WIDGET_DART_ENTRYPOINT)
                    FlutterUtils.runOnUiThread {
                        dartExecutor.executeDartEntrypoint(entrypoint)
                    }
                }
            }
        }

        private fun initChannels(context: Context) {
            val messenger = flutterEngine!!.dartExecutor

            // dart -> platform -> dart
            // - need Context
            MethodChannel(messenger, DeviceHandler.CHANNEL).setMethodCallHandler(DeviceHandler(context))
            MethodChannel(messenger, MediaStoreHandler.CHANNEL).setMethodCallHandler(MediaStoreHandler(context))
            MethodChannel(messenger, MediaFetchBytesHandler.CHANNEL, AvesByteSendingMethodCodec.INSTANCE).setMethodCallHandler(MediaFetchBytesHandler(context))
            MethodChannel(messenger, MediaFetchObjectHandler.CHANNEL).setMethodCallHandler(MediaFetchObjectHandler(context))
            MethodChannel(messenger, StorageHandler.CHANNEL).setMethodCallHandler(StorageHandler(context))

            // result streaming: dart -> platform ->->-> dart
            // - need Context
            StreamsChannel(messenger, ImageByteStreamHandler.CHANNEL).setStreamHandlerFactory { args -> ImageByteStreamHandler(context, args) }
            StreamsChannel(messenger, MediaStoreStreamHandler.CHANNEL).setStreamHandlerFactory { args -> MediaStoreStreamHandler(context, args) }
        }
    }
}
