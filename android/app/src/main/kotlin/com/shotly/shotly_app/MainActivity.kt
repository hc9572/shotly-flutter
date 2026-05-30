package com.shotly.shotly_app

import android.Manifest
import android.content.ClipData
import android.content.ContentUris
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.util.Size
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.firebase.analytics.FirebaseAnalytics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "shotly/native"
    private val permissionRequestCode = 9210
    private val pickImageRequestCode = 9211
    private val deleteImageRequestCode = 9212
    private val saveBackupRequestCode = 9213
    private val openBackupRequestCode = 9214
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPickImageResult: MethodChannel.Result? = null
    private var pendingDeleteImageResult: MethodChannel.Result? = null
    private var pendingSaveBackupResult: MethodChannel.Result? = null
    private var pendingOpenBackupResult: MethodChannel.Result? = null
    private var pendingBackupContent: String? = null
    private var pendingDeleteImageUri: Uri? = null
    private var pendingDeleteImageUris: List<Uri>? = null
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPhotoPermission" -> requestPhotoPermission(result)
                "hasPhotoPermission" -> result.success(hasPhotoPermission())
                "openPhotoSettings" -> openPhotoSettings(result)
                "openUrl" -> openUrl(call.argument<String>("url"), result)
                "logAnalyticsEvent" -> logAnalyticsEvent(
                    call.argument<String>("name"),
                    call.argument<Map<String, Any?>>("parameters"),
                    result
                )
                "getScreenshots" -> runOnIo(result) { loadScreenshots() }
                "pickImage" -> pickImage(result)
                "getImagePreview" -> runOnIo(result) { getImagePreviewPath(call.argument<String>("imageId")) }
                "deleteOriginalImage" -> deleteOriginalImage(call.argument<String>("imageId"), result)
                "deleteOriginalImages" -> deleteOriginalImages(call.argument<List<String>>("imageIds"), result)
                "shareImages" -> shareImages(call.argument<List<String>>("imageIds"), result)
                "saveBackupFile" -> saveBackupFile(call.argument<String>("filename"), call.argument<String>("content"), result)
                "openBackupFile" -> openBackupFile(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun <T> runOnIo(result: MethodChannel.Result, block: () -> T) {
        ioExecutor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Exception) {
                mainHandler.post { result.error("native_error", e.localizedMessage ?: "Native 작업 중 문제가 생겼어요.", null) }
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
        ActivityCompat.requestPermissions(this, photoPermissions(), permissionRequestCode)
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

    private fun openUrl(url: String?, result: MethodChannel.Result) {
        if (url.isNullOrBlank()) {
            result.error("invalid_url", "열 수 없는 링크예요.", null)
            return
        }
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("url_unavailable", "링크를 열 수 없어요.", null)
        }
    }

    private fun logAnalyticsEvent(name: String?, parameters: Map<String, Any?>?, result: MethodChannel.Result) {
        if (name.isNullOrBlank()) {
            result.success(false)
            return
        }
        return try {
            val bundle = Bundle()
            parameters.orEmpty().forEach { (key, value) ->
                when (value) {
                    is String -> bundle.putString(key, value)
                    is Int -> bundle.putInt(key, value)
                    is Long -> bundle.putLong(key, value)
                    is Double -> bundle.putDouble(key, value)
                    is Float -> bundle.putDouble(key, value.toDouble())
                    is Boolean -> bundle.putString(key, value.toString())
                }
            }
            FirebaseAnalytics.getInstance(this).logEvent(name, bundle)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun hasPhotoPermission(): Boolean {
        return photoPermissions().any { permission ->
            ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun photoPermissions(): Array<String> {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE -> arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
            )
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> arrayOf(Manifest.permission.READ_MEDIA_IMAGES)
            else -> arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }
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
        if (requestCode == deleteImageRequestCode) {
            val uris = pendingDeleteImageUris ?: pendingDeleteImageUri?.let { listOf(it) }.orEmpty()
            pendingDeleteImageResult?.success(resultCode == RESULT_OK || uris.all { !doesImageExist(it) })
            pendingDeleteImageResult = null
            pendingDeleteImageUri = null
            pendingDeleteImageUris = null
        }
        if (requestCode == saveBackupRequestCode) {
            val uri = data?.data
            val content = pendingBackupContent
            if (resultCode == RESULT_OK && uri != null && content != null) {
                try {
                    contentResolver.openOutputStream(uri)?.use { output ->
                        output.write(content.toByteArray(Charsets.UTF_8))
                    }
                    pendingSaveBackupResult?.success(true)
                } catch (e: Exception) {
                    pendingSaveBackupResult?.error("backup_save_failed", "백업 파일을 저장하지 못했어요.", null)
                }
            } else {
                pendingSaveBackupResult?.success(false)
            }
            pendingSaveBackupResult = null
            pendingBackupContent = null
        }
        if (requestCode == openBackupRequestCode) {
            val uri = data?.data
            if (resultCode == RESULT_OK && uri != null) {
                try {
                    val content = contentResolver.openInputStream(uri)?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }
                    pendingOpenBackupResult?.success(content)
                } catch (e: Exception) {
                    pendingOpenBackupResult?.error("backup_open_failed", "백업 파일을 열 수 없어요.", null)
                }
            } else {
                pendingOpenBackupResult?.success(null)
            }
            pendingOpenBackupResult = null
        }
    }

    private fun getImagePreview(imageId: String?, result: MethodChannel.Result) {
        result.success(getImagePreviewPath(imageId))
    }

    private fun getImagePreviewPath(imageId: String?): String {
        val uri = imageUriForId(imageId)
        if (uri == null) return ""
        return createOriginalCacheFileFromUri("original-${imageId.orEmpty()}", uri)
    }

    private fun deleteOriginalImage(imageId: String?, result: MethodChannel.Result) {
        deleteOriginalImages(listOfNotNull(imageId), result)
    }

    private fun deleteOriginalImages(imageIds: List<String>?, result: MethodChannel.Result) {
        val uris = imageIds.orEmpty().mapNotNull { imageUriForId(it) }
        if (uris.isEmpty()) {
            result.error("invalid_image_id", "삭제할 원본 이미지를 찾을 수 없어요.", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            pendingDeleteImageResult = result
            pendingDeleteImageUris = uris
            val request = MediaStore.createDeleteRequest(contentResolver, uris)
            return try {
                startIntentSenderForResult(request.intentSender, deleteImageRequestCode, null, 0, 0, 0, null)
            } catch (e: IntentSender.SendIntentException) {
                pendingDeleteImageResult = null
                pendingDeleteImageUri = null
                pendingDeleteImageUris = null
                result.error("delete_failed", "원본 파일 삭제 요청을 열 수 없어요.", null)
            }
        }
        try {
            val rows = uris.sumOf { contentResolver.delete(it, null, null) }
            result.success(rows > 0)
        } catch (e: SecurityException) {
            result.error("delete_permission_denied", "원본 파일 삭제 권한이 필요해요.", null)
        }
    }

    private fun deleteOriginalImageLegacy(imageId: String?, result: MethodChannel.Result) {
        val uri = imageUriForId(imageId)
        if (uri == null) {
            result.error("invalid_image_id", "삭제할 원본 이미지를 찾을 수 없어요.", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            pendingDeleteImageResult = result
            pendingDeleteImageUri = uri
            val request = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
            return try {
                startIntentSenderForResult(request.intentSender, deleteImageRequestCode, null, 0, 0, 0, null)
            } catch (e: IntentSender.SendIntentException) {
                pendingDeleteImageResult = null
                pendingDeleteImageUri = null
                result.error("delete_failed", "원본 파일 삭제 요청을 열 수 없어요.", null)
            }
        }
        try {
            val rows = contentResolver.delete(uri, null, null)
            result.success(rows > 0)
        } catch (e: SecurityException) {
            result.error("delete_permission_denied", "원본 파일 삭제 권한이 필요해요.", null)
        }
    }

    private fun shareImages(imageIds: List<String>?, result: MethodChannel.Result) {
        val uris = imageIds.orEmpty().mapNotNull { imageUriForId(it) }
        if (uris.isEmpty()) {
            result.success(false)
            return
        }
        val intent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                type = "image/*"
                putExtra(Intent.EXTRA_STREAM, uris.first())
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "image/*"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
            }
        }.apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = ClipData.newUri(contentResolver, "Shotly", uris.first())
        }
        startActivity(Intent.createChooser(intent, "Share via"))
        result.success(true)
    }

    private fun saveBackupFile(filename: String?, content: String?, result: MethodChannel.Result) {
        if (pendingSaveBackupResult != null) {
            result.error("backup_save_in_progress", "Backup save is already in progress.", null)
            return
        }
        if (content.isNullOrBlank()) {
            result.error("backup_empty", "백업할 데이터가 없어요.", null)
            return
        }
        pendingSaveBackupResult = result
        pendingBackupContent = content
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(Intent.EXTRA_TITLE, filename ?: "shotly-backup.json")
        }
        startActivityForResult(intent, saveBackupRequestCode)
    }

    private fun openBackupFile(result: MethodChannel.Result) {
        if (pendingOpenBackupResult != null) {
            result.error("backup_open_in_progress", "Backup picker is already open.", null)
            return
        }
        pendingOpenBackupResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
        }
        startActivityForResult(intent, openBackupRequestCode)
    }

    private fun imageUriForId(imageId: String?): Uri? {
        val numericId = imageId?.substringAfter("picked-", imageId)?.substringBefore("-")?.toLongOrNull() ?: return null
        return ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, numericId)
    }

    private fun doesImageExist(uri: Uri): Boolean {
        return contentResolver.query(uri, arrayOf(MediaStore.Images.Media._ID), null, null, null)?.use { cursor -> cursor.moveToFirst() } == true
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

    private fun createThumbnailFileFromUri(key: String, uri: android.net.Uri, legacyId: Long? = null, preview: Boolean = false): String {
        return try {
            val directory = File(cacheDir, "shotly_thumbs").apply { mkdirs() }
            val safeKey = key.replace(Regex("[^A-Za-z0-9_-]"), "_")
            val file = File(directory, "$safeKey.jpg")
            if (file.exists() && file.length() > 0) return file.absolutePath

            val bitmap: Bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentResolver.loadThumbnail(uri, if (preview) Size(1200, 2200) else Size(320, 320), null)
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

    private fun createOriginalCacheFileFromUri(key: String, uri: android.net.Uri): String {
        return try {
            val directory = File(cacheDir, "shotly_originals").apply { mkdirs() }
            val safeKey = key.replace(Regex("[^A-Za-z0-9_-]"), "_")
            val mimeType = contentResolver.getType(uri).orEmpty()
            val extension = when {
                mimeType.contains("png", ignoreCase = true) -> "png"
                mimeType.contains("webp", ignoreCase = true) -> "webp"
                else -> "jpg"
            }
            val file = File(directory, "$safeKey.$extension")
            if (file.exists() && file.length() > 0) return file.absolutePath

            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(file).use { output -> input.copyTo(output) }
            } ?: return ""
            file.absolutePath
        } catch (_: Exception) {
            ""
        }
    }
}
