package anonymity.ac.viewer

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import anonymity.ac.viewer.utils.LogUtils
import android.util.Log

class HomeScreenWidgetsPlugin(private val context: Context) : MethodCallHandler {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result){
        when (call.method) {
            "getHomeScreenWidgetIds" -> {
                Log.d(LOG_TAG, "getHomeScreenWidgetIds")
                result.success(getHomeScreenWidgetIds())
            }
            else -> result.notImplemented()
        }
    }

    private fun getHomeScreenWidgetIds() : List<Int> {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, HomeWidgetProvider::class.java)
        )
        return appWidgetIds.toList()
    }
    companion object {
        private val LOG_TAG = LogUtils.createTag<HomeScreenWidgetsPlugin>()
        const val CHANNEL = "anonymity.ac.viewer/aves/home_screen_widget"
    }
}
