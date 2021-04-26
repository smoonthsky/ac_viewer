package deckers.thibault.aves.metadata

import android.util.Log
import com.adobe.internal.xmp.XMPError
import com.adobe.internal.xmp.XMPException
import com.adobe.internal.xmp.XMPMeta
import deckers.thibault.aves.utils.LogUtils
import java.util.*

object XMP {
    private val LOG_TAG = LogUtils.createTag<XMP>()

    // standard namespaces
    // cf com.adobe.internal.xmp.XMPConst
    const val DC_SCHEMA_NS = "http://purl.org/dc/elements/1.1/"
    const val PHOTOSHOP_SCHEMA_NS = "http://ns.adobe.com/photoshop/1.0/"
    const val XMP_SCHEMA_NS = "http://ns.adobe.com/xap/1.0/"

    const val SUBJECT_PROP_NAME = "dc:subject"
    const val TITLE_PROP_NAME = "dc:title"
    const val DESCRIPTION_PROP_NAME = "dc:description"
    const val PS_DATE_CREATED_PROP_NAME = "photoshop:DateCreated"
    const val CREATE_DATE_PROP_NAME = "xmp:CreateDate"

    private const val GENERIC_LANG = ""
    private const val SPECIFIC_LANG = "en-US"

    private val schemas = hashMapOf(
        "GAudio" to "http://ns.google.com/photos/1.0/audio/",
        "GDepth" to "http://ns.google.com/photos/1.0/depthmap/",
        "GImage" to "http://ns.google.com/photos/1.0/image/",
        "xmp" to XMP_SCHEMA_NS,
        "xmpGImg" to "http://ns.adobe.com/xap/1.0/g/img/",
    )

    fun namespaceForPropPath(propPath: String) = schemas[propPath.split(":")[0]]

    // embedded media data properties
    // cf https://developers.google.com/depthmap-metadata
    // cf https://developers.google.com/vr/reference/cardboard-camera-vr-photo-format
    private val knownDataPaths = listOf("GAudio:Data", "GImage:Data", "GDepth:Data", "GDepth:Confidence")

    fun isDataPath(path: String) = knownDataPaths.contains(path)

    // motion photo

    const val GCAMERA_SCHEMA_NS = "http://ns.google.com/photos/1.0/camera/"

    const val GCAMERA_VIDEO_OFFSET_PROP_NAME = "GCamera:MicroVideoOffset"

    // panorama
    // cf https://developers.google.com/streetview/spherical-metadata

    const val GPANO_SCHEMA_NS = "http://ns.google.com/photos/1.0/panorama/"
    private const val PMTM_SCHEMA_NS = "http://www.hdrsoft.com/photomatix_settings01"

    const val GPANO_CROPPED_AREA_HEIGHT_PROP_NAME = "GPano:CroppedAreaImageHeightPixels"
    const val GPANO_CROPPED_AREA_WIDTH_PROP_NAME = "GPano:CroppedAreaImageWidthPixels"
    const val GPANO_CROPPED_AREA_LEFT_PROP_NAME = "GPano:CroppedAreaLeftPixels"
    const val GPANO_CROPPED_AREA_TOP_PROP_NAME = "GPano:CroppedAreaTopPixels"
    const val GPANO_FULL_PANO_HEIGHT_PROP_NAME = "GPano:FullPanoHeightPixels"
    const val GPANO_FULL_PANO_WIDTH_PROP_NAME = "GPano:FullPanoWidthPixels"
    const val GPANO_PROJECTION_TYPE_PROP_NAME = "GPano:ProjectionType"
    const val GPANO_PROJECTION_TYPE_DEFAULT = "equirectangular"

    private const val PMTM_IS_PANO360 = "pmtm:IsPano360"

    // `GPano:ProjectionType` is required by spec but it is sometimes missing, assuming default
    // `GPano:FullPanoHeightPixels` is required by spec but it is sometimes missing (e.g. Samsung Camera app panorama mode)
    private val gpanoRequiredProps = listOf(
        GPANO_CROPPED_AREA_HEIGHT_PROP_NAME,
        GPANO_CROPPED_AREA_WIDTH_PROP_NAME,
        GPANO_CROPPED_AREA_LEFT_PROP_NAME,
        GPANO_CROPPED_AREA_TOP_PROP_NAME,
        GPANO_FULL_PANO_WIDTH_PROP_NAME,
    )

    // extensions

    fun XMPMeta.isPanorama(): Boolean {
        // Google
        try {
            if (gpanoRequiredProps.all { doesPropertyExist(GPANO_SCHEMA_NS, it) }) return true
        } catch (e: XMPException) {
            if (e.errorCode != XMPError.BADSCHEMA) {
                // `BADSCHEMA` code is reported when we check a property
                // from a non standard namespace, and that namespace is not declared in the XMP
                Log.w(LOG_TAG, "failed to check Google panorama props from XMP", e)
            }
        }

        // Photomatix
        try {
            if (getPropertyString(PMTM_SCHEMA_NS, PMTM_IS_PANO360) == "Yes") return true
        } catch (e: XMPException) {
            if (e.errorCode != XMPError.BADSCHEMA) {
                // `BADSCHEMA` code is reported when we check a property
                // from a non standard namespace, and that namespace is not declared in the XMP
                Log.w(LOG_TAG, "failed to check Photomatix panorama props from XMP", e)
            }
        }

        return false
    }

    fun XMPMeta.getSafeInt(schema: String, propName: String, save: (value: Int) -> Unit) {
        try {
            if (doesPropertyExist(schema, propName)) {
                val item = getPropertyInteger(schema, propName)
                // double check retrieved items as the property sometimes is reported to exist but it is actually null
                if (item != null) {
                    save(item)
                }
            }
        } catch (e: XMPException) {
            Log.w(LOG_TAG, "failed to get int for XMP schema=$schema, propName=$propName", e)
        }
    }

    fun XMPMeta.getSafeLong(schema: String, propName: String, save: (value: Long) -> Unit) {
        try {
            if (doesPropertyExist(schema, propName)) {
                val item = getPropertyLong(schema, propName)
                // double check retrieved items as the property sometimes is reported to exist but it is actually null
                if (item != null) {
                    save(item)
                }
            }
        } catch (e: XMPException) {
            Log.w(LOG_TAG, "failed to get long for XMP schema=$schema, propName=$propName", e)
        }
    }

    fun XMPMeta.getSafeString(schema: String, propName: String, save: (value: String) -> Unit) {
        try {
            if (doesPropertyExist(schema, propName)) {
                val item = getPropertyString(schema, propName)
                // double check retrieved items as the property sometimes is reported to exist but it is actually null
                if (item != null) {
                    save(item)
                }
            }
        } catch (e: XMPException) {
            Log.w(LOG_TAG, "failed to get int for XMP schema=$schema, propName=$propName", e)
        }
    }

    fun XMPMeta.getSafeLocalizedText(schema: String, propName: String, acceptBlank: Boolean = true, save: (value: String) -> Unit) {
        try {
            if (doesPropertyExist(schema, propName)) {
                val item = getLocalizedText(schema, propName, GENERIC_LANG, SPECIFIC_LANG)
                // double check retrieved items as the property sometimes is reported to exist but it is actually null
                if (item != null && (acceptBlank || item.value.isNotBlank())) {
                    save(item.value)
                }
            }
        } catch (e: XMPException) {
            Log.w(LOG_TAG, "failed to get text for XMP schema=$schema, propName=$propName", e)
        }
    }

    fun XMPMeta.getSafeDateMillis(schema: String, propName: String, save: (value: Long) -> Unit) {
        try {
            if (doesPropertyExist(schema, propName)) {
                val item = getPropertyDate(schema, propName)
                // double check retrieved items as the property sometimes is reported to exist but it is actually null
                if (item != null) {
                    // strip time zone from XMP dates so that we show date/times as local ones
                    // this aligns with Exif date/times, which are specified without time zones
                    item.timeZone = TimeZone.getDefault()
                    save(item.calendar.timeInMillis)
                }
            }
        } catch (e: XMPException) {
            Log.w(LOG_TAG, "failed to get date for XMP schema=$schema, propName=$propName", e)
        }
    }
}