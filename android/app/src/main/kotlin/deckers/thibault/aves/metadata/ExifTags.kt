package anonymity.ac.viewer.metadata

/*
Exif tags missing from `metadata-extractor`

Photoshop
https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/
https://www.adobe.io/content/dam/udp/en/open/standards/tiff/TIFFphotoshop.pdf
 */
object ExifTags {
    private const val PROCESSING_SOFTWARE = 0x000b
    private const val X_POSITION = 0x011e
    private const val Y_POSITION = 0x011f
    private const val T4_OPTIONS = 0x0124
    private const val T6_OPTIONS = 0x0125
    private const val COLOR_MAP = 0x0140
    private const val EXTRA_SAMPLES = 0x0152
    private const val SAMPLE_FORMAT = 0x0153
    private const val SMIN_SAMPLE_VALUE = 0x0154
    private const val SMAX_SAMPLE_VALUE = 0x0155
    private const val RATING_PERCENT = 0x4749
    private const val SONY_RAW_FILE_TYPE = 0x7000
    private const val SONY_TONE_CURVE = 0x7010
    private const val MATTEING = 0x80e3

    // sensing method (0x9217) redundant with sensing method (0xA217)
    private const val SENSING_METHOD = 0x9217
    private const val IMAGE_SOURCE_DATA = 0x935c
    private const val GDAL_METADATA = 0xa480
    private const val GDAL_NO_DATA = 0xa481

    private val tagNameMap = hashMapOf(
        PROCESSING_SOFTWARE to "Processing Software",
        X_POSITION to "X Position",
        Y_POSITION to "Y Position",
        T4_OPTIONS to "T4 Options",
        T6_OPTIONS to "T6 Options",
        COLOR_MAP to "Color Map",
        EXTRA_SAMPLES to "Extra Samples",
        SAMPLE_FORMAT to "Sample Format",
        SMIN_SAMPLE_VALUE to "S Min Sample Value",
        SMAX_SAMPLE_VALUE to "S Max Sample Value",
        RATING_PERCENT to "Rating Percent",
        SONY_RAW_FILE_TYPE to "Sony Raw File Type",
        SONY_TONE_CURVE to "Sony Tone Curve",
        MATTEING to "Matteing",
        SENSING_METHOD to "Sensing Method (0x9217)",
        IMAGE_SOURCE_DATA to "Image Source Data",
        GDAL_METADATA to "GDAL Metadata",
        GDAL_NO_DATA to "GDAL No Data",
    ).apply {
        putAll(DngTags.tagNameMap)
        putAll(ExifGeoTiffTags.tagNameMap)
    }

    fun isDngTag(tag: Int) = DngTags.tags.contains(tag)

    fun isGeoTiffTag(tag: Int) = ExifGeoTiffTags.tags.contains(tag)

    fun getTagName(tag: Int): String? {
        return tagNameMap[tag]
    }
}