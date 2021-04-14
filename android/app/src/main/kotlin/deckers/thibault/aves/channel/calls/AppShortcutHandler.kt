package deckers.thibault.aves.channel.calls

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import deckers.thibault.aves.MainActivity
import deckers.thibault.aves.R
import deckers.thibault.aves.utils.BitmapUtils.centerSquareCrop
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.util.*

class AppShortcutHandler(private val context: Context) : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canPin" -> result.success(canPin())
            "pin" -> {
                GlobalScope.launch(Dispatchers.IO) { pin(call) }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun canPin() = ShortcutManagerCompat.isRequestPinShortcutSupported(context)

    private fun pin(call: MethodCall) {
        if (!canPin()) return

        val label = call.argument<String>("label") ?: return
        val iconBytes = call.argument<ByteArray>("iconBytes")
        val filters = call.argument<List<String>>("filters") ?: return

        var icon: IconCompat? = null
        if (iconBytes?.isNotEmpty() == true) {
            var bitmap = BitmapFactory.decodeByteArray(iconBytes, 0, iconBytes.size)
            bitmap = centerSquareCrop(context, bitmap, 256)
            if (bitmap != null) {
                icon = IconCompat.createWithBitmap(bitmap)
            }
        }
        if (icon == null) {
            icon = IconCompat.createWithResource(context, R.mipmap.ic_shortcut_collection)
        }

        val intent = Intent(Intent.ACTION_MAIN, null, context, MainActivity::class.java)
            .putExtra("page", "/collection")
            .putExtra("filters", filters.toTypedArray())

        // multiple shortcuts sharing the same ID cannot be created with different labels or icons
        // so we provide a unique ID for each one, and let the user manage duplicates (i.e. same filter set), if any
        val shortcut = ShortcutInfoCompat.Builder(context, UUID.randomUUID().toString())
            .setShortLabel(label)
            .setIcon(icon)
            .setIntent(intent)
            .build()
        ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)
    }

    companion object {
        const val CHANNEL = "deckers.thibault/aves/shortcut"
    }
}