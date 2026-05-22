package com.shotly.shotly_app

import android.Manifest
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.provider.Settings
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
    private val pickImageRequestCode = 9211
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPickImageResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPhotoPermission" -> requestPhotoPermission(result)
                "openPhotoSettings" -> openPhotoSettings(result)
                "getScreenshots" -> result.success(loadScreenshots())
                "pickImage" -> pickImage(result)
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

    private fun openPhotoSettings(result: MethodChannel.Result) {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("settings_unavailable", "시스템 설정을 열 수 없어요.", null)
        }
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

    private fun pickImage(result: MethodChannel.Result) {
        if (pendingPickImageResult != null) {
            result.error("picker_in_progress", "Image picker is already open.", null)
            return
        }
        pendingPickImageResult = result
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
            type = "image/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(intent, pickImageRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == pickImageRequestCode) {
            val uri = data?.data
            if (resultCode == RESULT_OK && uri != null) {
                pendingPickImageResult?.success(buildImageItemFromUri(uri))
            } else {
                pendingPickImageResult?.success(null)
            }
            pendingPickImageResult = null
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

    private fun buildImageItemFromUri(uri: Uri): Map<String, Any?> {
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATE_TAKEN,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.RELATIVE_PATH
        )
        var id = System.currentTimeMillis().toString()
        var displayName = "Selected image"
        var relativePath = ""
        var dateMillis = System.currentTimeMillis()

        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumn = cursor.getColumnIndex(MediaStore.Images.Media._ID)
                val nameColumn = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                val dateTakenColumn = cursor.getColumnIndex(MediaStore.Images.Media.DATE_TAKEN)
                val dateAddedColumn = cursor.getColumnIndex(MediaStore.Images.Media.DATE_ADDED)
                val pathColumn = cursor.getColumnIndex(MediaStore.Images.Media.RELATIVE_PATH)
                if (idColumn >= 0) id = cursor.getLong(idColumn).toString()
                if (nameColumn >= 0) displayName = cursor.getString(nameColumn).orEmpty().ifBlank { displayName }
                if (pathColumn >= 0) relativePath = cursor.getString(pathColumn).orEmpty()
                val dateTaken = if (dateTakenColumn >= 0) cursor.getLong(dateTakenColumn) else 0L
                val dateAdded = if (dateAddedColumn >= 0) cursor.getLong(dateAddedColumn) * 1000L else 0L
                dateMillis = when {
                    dateTaken > 0 -> dateTaken
                    dateAdded > 0 -> dateAdded
                    else -> dateMillis
                }
            }
        }

        return mapOf(
            "id" to "picked-$id-${System.currentTimeMillis()}",
            "displayName" to displayName,
            "relativePath" to relativePath,
            "dateTakenMillis" to dateMillis,
            "appName" to inferAppName(displayName, relativePath),
            "thumbnailPath" to createThumbnailFileFromUri("picked-$id", uri)
        )
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
        return createThumbnailFileFromUri(id.toString(), uri, id)
    }

    private fun createThumbnailFileFromUri(key: String, uri: android.net.Uri, legacyId: Long? = null): String {
        return try {
            val directory = File(cacheDir, "shotly_thumbs").apply { mkdirs() }
            val safeKey = key.replace(Regex("[^A-Za-z0-9_-]"), "_")
            val file = File(directory, "$safeKey.jpg")
            if (file.exists() && file.length() > 0) return file.absolutePath

            val bitmap: Bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentResolver.loadThumbnail(uri, Size(320, 320), null)
            } else if (legacyId != null) {
                MediaStore.Images.Thumbnails.getThumbnail(contentResolver, legacyId, MediaStore.Images.Thumbnails.MINI_KIND, null)
            } else {
                MediaStore.Images.Media.getBitmap(contentResolver, uri)
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
