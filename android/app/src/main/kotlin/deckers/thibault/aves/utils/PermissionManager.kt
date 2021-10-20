package deckers.thibault.aves.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.RequiresApi
import deckers.thibault.aves.MainActivity
import deckers.thibault.aves.PendingStorageAccessResultHandler
import deckers.thibault.aves.model.FieldMap
import deckers.thibault.aves.utils.StorageUtils.PathSegments
import java.io.File
import java.util.*
import java.util.concurrent.CompletableFuture
import kotlin.collections.ArrayList

object PermissionManager {
    private val LOG_TAG = LogUtils.createTag<PermissionManager>()

    private val MEDIA_STORE_INSERTION_PRIMARY_DIRS = listOf(
        Environment.DIRECTORY_DCIM,
        Environment.DIRECTORY_DOWNLOADS,
        Environment.DIRECTORY_PICTURES,
    )

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun requestDirectoryAccess(activity: Activity, path: String, onGranted: (uri: Uri) -> Unit, onDenied: () -> Unit) {
        Log.i(LOG_TAG, "request user to select and grant access permission to path=$path")

        var intent: Intent? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val sm = activity.getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            intent = sm?.getStorageVolume(File(path))?.createOpenDocumentTreeIntent()
        }

        // fallback to basic open document tree intent
        if (intent == null) {
            intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        }

        if (intent.resolveActivity(activity.packageManager) != null) {
            MainActivity.pendingStorageAccessResultHandlers[MainActivity.DOCUMENT_TREE_ACCESS_REQUEST] = PendingStorageAccessResultHandler(path, onGranted, onDenied)
            activity.startActivityForResult(intent, MainActivity.DOCUMENT_TREE_ACCESS_REQUEST)
        } else {
            Log.e(LOG_TAG, "failed to resolve activity for intent=$intent")
            onDenied()
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    fun requestMediaFileAccess(activity: Activity, uris: List<Uri>, mimeTypes: List<String>): Boolean {
        val safeUris = uris.mapIndexed { index, uri -> StorageUtils.getMediaStoreScopedStorageSafeUri(uri, mimeTypes[index]) }

        val todoUris = ArrayList<Uri>()
        val pid = Binder.getCallingPid()
        val uid = Binder.getCallingUid()
        val flags = Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            activity.checkUriPermissions(safeUris, pid, uid, flags)
        } else {
            safeUris.map { activity.checkUriPermission(it, pid, uid, flags) }.toIntArray()
        }.forEachIndexed { index, permission ->
            if (permission != PackageManager.PERMISSION_GRANTED) {
                todoUris.add(safeUris[index])
            }
        }
        if (todoUris.isEmpty()) return true

        Log.i(LOG_TAG, "request user to select and grant access permission to uris=$todoUris")
        val intentSender = MediaStore.createWriteRequest(activity.contentResolver, safeUris).intentSender
        MainActivity.pendingScopedStoragePermissionCompleter = CompletableFuture<Boolean>()
        activity.startIntentSenderForResult(intentSender, MainActivity.MEDIA_WRITE_BULK_PERMISSION_REQUEST, null, 0, 0, 0, null)
        val granted = MainActivity.pendingScopedStoragePermissionCompleter!!.join()
        MainActivity.pendingScopedStoragePermissionCompleter = null

        return granted
    }

    fun getGrantedDirForPath(context: Context, anyPath: String): String? {
        return getAccessibleDirs(context).firstOrNull { anyPath.startsWith(it) }
    }

    fun getInaccessibleDirectories(context: Context, dirPaths: List<String>): List<Map<String, String>> {
        val accessibleDirs = getAccessibleDirs(context)

        // find set of inaccessible directories for each volume
        val dirsPerVolume = HashMap<String, MutableSet<String>>()
        for (dirPath in dirPaths.map { if (it.endsWith(File.separator)) it else it + File.separator }) {
            if (accessibleDirs.none { dirPath.startsWith(it) }) {
                // inaccessible dirs
                val segments = PathSegments(context, dirPath)
                segments.volumePath?.let { volumePath ->
                    val dirSet = dirsPerVolume[volumePath] ?: HashSet()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        // request primary directory on volume from Android R
                        val relativeDir = segments.relativeDir
                        if (relativeDir != null) {
                            val dirSegments = relativeDir.split(File.separator).takeWhile { it.isNotEmpty() }
                            val primaryDir = dirSegments.firstOrNull()
                            if (primaryDir == Environment.DIRECTORY_DOWNLOADS && dirSegments.size > 1) {
                                // request secondary directory (if any) for restricted primary directory
                                dirSet.add(dirSegments.take(2).joinToString(File.separator))
                            } else {
                                primaryDir?.let { dirSet.add(it) }
                            }
                        } else {
                            // the requested path is the volume root itself
                            // which cannot be granted, due to Android R restrictions
                            dirSet.add("")
                        }
                    } else {
                        // request volume root until Android Q
                        dirSet.add("")
                    }
                    dirsPerVolume[volumePath] = dirSet
                }
            }
        }

        // format for easier handling on Flutter
        return ArrayList<Map<String, String>>().apply {
            addAll(dirsPerVolume.flatMap { (volumePath, relativeDirs) ->
                relativeDirs.map { relativeDir ->
                    hashMapOf(
                        "volumePath" to volumePath,
                        "relativeDir" to relativeDir,
                    )
                }
            })
        }
    }

    fun getRestrictedDirectories(context: Context): List<Map<String, String>> {
        val dirs = ArrayList<Map<String, String>>()
        val sdkInt = Build.VERSION.SDK_INT

        if (sdkInt >= Build.VERSION_CODES.R) {
            // cf https://developer.android.com/about/versions/11/privacy/storage#directory-access
            val volumePaths = StorageUtils.getVolumePaths(context)
            dirs.addAll(volumePaths.map {
                hashMapOf(
                    "volumePath" to it,
                    "relativeDir" to "",
                )
            })
            dirs.addAll(volumePaths.map {
                hashMapOf(
                    "volumePath" to it,
                    "relativeDir" to Environment.DIRECTORY_DOWNLOADS,
                )
            })
        } else if (sdkInt == Build.VERSION_CODES.KITKAT || sdkInt == Build.VERSION_CODES.KITKAT_WATCH) {
            // no SD card volume access on KitKat
            val primaryVolume = StorageUtils.getPrimaryVolumePath(context)
            val nonPrimaryVolumes = StorageUtils.getVolumePaths(context).filter { it != primaryVolume }
            dirs.addAll(nonPrimaryVolumes.map {
                hashMapOf(
                    "volumePath" to it,
                    "relativeDir" to "",
                )
            })
        }
        return dirs
    }

    fun canInsertByMediaStore(directories: List<FieldMap>): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            directories.all {
                val relativeDir = it["relativeDir"] as String
                val segments = relativeDir.split(File.separator)
                segments.isNotEmpty() && MEDIA_STORE_INSERTION_PRIMARY_DIRS.contains(segments.first())
            }
        } else {
            true
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun revokeDirectoryAccess(context: Context, path: String): Boolean {
        return StorageUtils.convertDirPathToTreeUri(context, path)?.let {
            releaseUriPermission(context, it)
            true
        } ?: false
    }

    // returns paths matching URIs granted by the user
    fun getGrantedDirs(context: Context): Set<String> {
        val grantedDirs = HashSet<String>()
        for (uriPermission in context.contentResolver.persistedUriPermissions) {
            val dirPath = StorageUtils.convertTreeUriToDirPath(context, uriPermission.uri)
            dirPath?.let { grantedDirs.add(it) }
        }
        return grantedDirs
    }

    // returns paths accessible to the app (granted by the user or by default)
    private fun getAccessibleDirs(context: Context): Set<String> {
        val accessibleDirs = HashSet(getGrantedDirs(context))
        // from Android R, we no longer have access permission by default on primary volume
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) {
            accessibleDirs.add(StorageUtils.getPrimaryVolumePath(context))
        }
        return accessibleDirs
    }

    // As of Android R, `MediaStore.getDocumentUri` fails if any of the persisted
    // URI permissions we hold points to a folder that no longer exists,
    // so we should remove these obsolete URIs before proceeding.
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun sanitizePersistedUriPermissions(context: Context) {
        try {
            for (uriPermission in context.contentResolver.persistedUriPermissions) {
                val uri = uriPermission.uri
                val path = StorageUtils.convertTreeUriToDirPath(context, uri)
                if (path != null && !File(path).exists()) {
                    Log.d(LOG_TAG, "revoke URI permission for obsolete path=$path")
                    releaseUriPermission(context, uri)
                }
            }
        } catch (e: Exception) {
            Log.w(LOG_TAG, "failed to sanitize persisted URI permissions", e)
        }
    }

    private fun releaseUriPermission(context: Context, it: Uri) {
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        context.contentResolver.releasePersistableUriPermission(it, flags)
    }
}