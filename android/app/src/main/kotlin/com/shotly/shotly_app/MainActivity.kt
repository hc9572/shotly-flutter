package com.shotly.shotly_app

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Size
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "shotly/native"
    private val permissionRequestCode = 9210
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPhotoPermission" -> requestPhotoPermission(result)
                "getScreenshots" -> result.success(loadScreenshots())
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPhotoPermission(result: MethodChannel.Result) {
        if (hasPhotoPermission()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission_in_progress", "Photo permission request is already in progress.", null)
            return
        }
        pendingPermissionResult = result
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_IMAGES
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
        ActivityCompat.requestPermissions(this, arrayOf(permission), permissionRequestCode)
    }

    private fun hasPhotoPermission(): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_IMAGES
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun loadScreenshots(): List<Map<String, Any?>> {
        if (!hasPhotoPermission()) return emptyList()

        val collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATE_TAKEN,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.RELATIVE_PATH
        )
        val sortOrder = "${MediaStore.Images.Media.DATE_TAKEN} DESC"
        val items = mutableListOf<Map<String, Any?>>()

        contentResolver.query(collection, projection, null, null, sortOrder)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
            val dateTakenColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_TAKEN)
            val dateAddedColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
            val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.RELATIVE_PATH)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val displayName = cursor.getString(nameColumn).orEmpty()
                val relativePath = cursor.getString(pathColumn).orEmpty()
                if (!isScreenshot(displayName, relativePath)) continue

                val dateTaken = cursor.getLong(dateTakenColumn)
                val dateAdded = cursor.getLong(dateAddedColumn) * 1000L
                val dateMillis = if (dateTaken > 0) dateTaken else dateAdded
                val uri = ContentUris.withAppendedId(collection, id)
                val thumbnailPath = createThumbnailFile(id, uri)

                items.add(
                    mapOf(
                        "id" to id.toString(),
                        "displayName" to displayName,
                        "relativePath" to relativePath,
                        "dateTakenMillis" to dateMillis,
                        "appName" to inferAppName(displayName, relativePath),
                        "thumbnailPath" to thumbnailPath
                    )
                )
            }
        }

        return items
    }

    private fun isScreenshot(displayName: String, relativePath: String): Boolean {
        val haystack = "$displayName $relativePath".lowercase()
        return haystack.contains("screenshot") || haystack.contains("screenshots") || haystack.contains("스크린샷")
    }

    private fun inferAppName(displayName: String, relativePath: String): String {
        val nameWithoutExt = displayName.substringBeforeLast('.')
        val known = listOf(
            "SmartThings", "Instagram", "KakaoTalk", "Karrot", "Chrome", "YouTube", "Naver", "Slack", "Discord", "Telegram", "Figma"
        )
        known.firstOrNull { nameWithoutExt.contains(it, ignoreCase = true) || relativePath.contains(it, ignoreCase = true) }?.let { return it }

        val patterns = listOf(
            Regex("Screenshot[_ -]\\d{8}[_ -]\\d{6}[_ -](.+)", RegexOption.IGNORE_CASE),
            Regex("Screenshot[_ -]\\d{4}[-_]\\d{2}[-_]\\d{2}[-_]\\d{2}[-_]\\d{2}[-_]\\d{2}[_ -](.+)", RegexOption.IGNORE_CASE),
            Regex("스크린샷[_ -].*?[_ -](.+)")
        )
        for (pattern in patterns) {
            val match = pattern.find(nameWithoutExt)
            val candidate = match?.groupValues?.getOrNull(1)?.trim('_', '-', ' ')
            if (!candidate.isNullOrBlank()) return cleanAppName(candidate)
        }

        val pathParts = relativePath.split('/').filter { it.isNotBlank() }
        val beforeScreenshots = pathParts.dropLastWhile { !it.equals("Screenshots", ignoreCase = true) }.dropLast(1).lastOrNull()
        if (!beforeScreenshots.isNullOrBlank() && !beforeScreenshots.equals("Pictures", ignoreCase = true) && !beforeScreenshots.equals("DCIM", ignoreCase = true)) {
            return cleanAppName(beforeScreenshots)
        }

        return "Unknown"
    }

    private fun cleanAppName(value: String): String {
        return value
            .replace(Regex("[_-]+"), " ")
            .trim()
            .take(32)
            .ifBlank { "Unknown" }
    }

    private fun createThumbnailFile(id: Long, uri: android.net.Uri): String {
        return try {
            val directory = File(cacheDir, "shotly_thumbs").apply { mkdirs() }
            val file = File(directory, "$id.jpg")
            if (file.exists() && file.length() > 0) return file.absolutePath

            val bitmap: Bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentResolver.loadThumbnail(uri, Size(320, 320), null)
            } else {
                MediaStore.Images.Thumbnails.getThumbnail(contentResolver, id, MediaStore.Images.Thumbnails.MINI_KIND, null)
            }
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 82, out)
            }
            bitmap.recycle()
            file.absolutePath
        } catch (_: Exception) {
            ""
        }
    }
}
