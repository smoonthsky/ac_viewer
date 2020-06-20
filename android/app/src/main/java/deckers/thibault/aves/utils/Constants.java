package deckers.thibault.aves.utils;

import android.media.MediaMetadataRetriever;
import android.os.Build;

import java.util.HashMap;
import java.util.Map;

public class Constants {
    public static final int SD_CARD_PERMISSION_REQUEST_CODE = 1;

    // video metadata keys, from android.media.MediaMetadataRetriever

    public static final Map<Integer, String> MEDIA_METADATA_KEYS = new HashMap<Integer, String>() {
        {
            put(MediaMetadataRetriever.METADATA_KEY_ALBUM, "Album");
            put(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST, "Album Artist");
            put(MediaMetadataRetriever.METADATA_KEY_ARTIST, "Artist");
            put(MediaMetadataRetriever.METADATA_KEY_AUTHOR, "Author");
            put(MediaMetadataRetriever.METADATA_KEY_BITRATE, "Bitrate");
            put(MediaMetadataRetriever.METADATA_KEY_COMPOSER, "Composer");
            put(MediaMetadataRetriever.METADATA_KEY_DATE, "Date");
            put(MediaMetadataRetriever.METADATA_KEY_GENRE, "Content Type");
            put(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO, "Has Audio");
            put(MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO, "Has Video");
            put(MediaMetadataRetriever.METADATA_KEY_LOCATION, "Location");
            put(MediaMetadataRetriever.METADATA_KEY_MIMETYPE, "MIME Type");
            put(MediaMetadataRetriever.METADATA_KEY_NUM_TRACKS, "Number of Tracks");
            put(MediaMetadataRetriever.METADATA_KEY_TITLE, "Title");
            put(MediaMetadataRetriever.METADATA_KEY_WRITER, "Writer");
            put(MediaMetadataRetriever.METADATA_KEY_YEAR, "Year");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                put(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT, "Frame Count");
            }
            // TODO TLAD comment? category?
        }
    };
}
