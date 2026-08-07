package com.ganne.music_downloader

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ganne.media_scanner"
    private val CUSTOM_LOCATION_REQUEST_CODE = 1001
    private val CUSTOM_TREE_URI_KEY = "custom_download_tree_uri"
    private val CUSTOM_TREE_URIS_KEY = "custom_download_tree_uris"
    private val CUSTOM_GANNE_TREE_URIS_KEY = "custom_download_ganne_tree_uris"
    private val CUSTOM_PUBLISHED_URIS_KEY = "custom_download_published_uris"
    private val CUSTOM_USE_GANNE_FOLDER_KEY = "custom_download_use_ganne_folder"
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private var customLocationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPublicDownloadPath" -> {
                    val location = call.argument<String>("location") ?: "music"
                    result.success(File(publicDownloadDirectory(location), "Ganne").absolutePath)
                }
                "getCustomDownloadLocation" -> {
                    result.success(customDownloadLocationDetails())
                }
                "selectCustomDownloadLocation" -> {
                    selectCustomDownloadLocation(result)
                }
                "setCustomDownloadFolderMode" -> {
                    val useGanneFolder = call.argument<Boolean>("useGanneFolder") ?: false
                    getSharedPreferences(packageName, MODE_PRIVATE).edit()
                        .putBoolean(CUSTOM_USE_GANNE_FOLDER_KEY, useGanneFolder)
                        .apply()
                    result.success(null)
                }
                "needsLegacyStoragePermission" -> {
                    result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
                }
                "publishFile" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val displayName = call.argument<String>("displayName")
                    val relativeDirectory = call.argument<String>("relativeDirectory")
                    val mimeType = call.argument<String>("mimeType")
                    val location = call.argument<String>("location") ?: "music"
                    if (sourcePath == null || displayName == null || relativeDirectory == null || mimeType == null) {
                        result.error("INVALID_ARG", "Source path, name, directory, and MIME type are required", null)
                        return@setMethodCallHandler
                    }

                    ioExecutor.execute {
                        try {
                            val published = publishFile(
                                sourcePath,
                                displayName,
                                relativeDirectory,
                                mimeType,
                                location,
                            )
                            runOnUiThread { result.success(published) }
                        } catch (error: Exception) {
                            runOnUiThread {
                                result.error("PUBLISH_FAILED", error.message, error.toString())
                            }
                        }
                    }
                }
                "deleteFile" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARG", "Path is required", null)
                        return@setMethodCallHandler
                    }

                    ioExecutor.execute {
                        try {
                            val deleted = deletePublishedFile(path)
                            runOnUiThread { result.success(deleted) }
                        } catch (error: Exception) {
                            runOnUiThread {
                                result.error("DELETE_FAILED", error.message, error.toString())
                            }
                        }
                    }
                }
                "deleteAllPublished" -> {
                    ioExecutor.execute {
                        try {
                            val deleted = deleteAllPublishedFiles()
                            runOnUiThread { result.success(deleted) }
                        } catch (error: Exception) {
                            runOnUiThread {
                                result.error("DELETE_FAILED", error.message, error.toString())
                            }
                        }
                    }
                }
                "openDocument" -> {
                    val uri = call.argument<String>("uri")
                    if (uri == null) {
                        result.error("INVALID_ARG", "Document URI is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(openDocument(Uri.parse(uri)))
                    } catch (error: Exception) {
                        result.error("OPEN_FAILED", error.message, error.toString())
                    }
                }
                "copyDocumentForPlayback" -> {
                    val uri = call.argument<String>("uri")
                    if (uri == null) {
                        result.error("INVALID_ARG", "Document URI is required", null)
                        return@setMethodCallHandler
                    }
                    ioExecutor.execute {
                        try {
                            val cachedPath = copyDocumentForPlayback(Uri.parse(uri))
                            runOnUiThread { result.success(cachedPath) }
                        } catch (error: Exception) {
                            runOnUiThread {
                                result.error("PLAYBACK_COPY_FAILED", error.message, error.toString())
                            }
                        }
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        MediaScannerConnection.scanFile(this, arrayOf(path), null) { _, uri ->
                            result.success(uri?.toString())
                        }
                    } else {
                        result.error("INVALID_ARG", "Path is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        customLocationResult?.error(
            "ACTIVITY_DESTROYED",
            "Folder picker was interrupted",
            null,
        )
        customLocationResult = null
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CUSTOM_LOCATION_REQUEST_CODE) return

        val result = customLocationResult ?: return
        customLocationResult = null
        val pickerData = data ?: run {
            result.success(null)
            return
        }
        val uri = pickerData.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        try {
            val grantedFlags = pickerData.flags and (
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            contentResolver.takePersistableUriPermission(uri, grantedFlags)
            persistCustomDownloadTree(uri)
            result.success(customDownloadLocationDetails())
        } catch (error: Exception) {
            result.error("PICKER_FAILED", error.message, error.toString())
        }
    }

    private fun storageDirectory(location: String): String = when (location) {
        "downloads" -> Environment.DIRECTORY_DOWNLOADS
        "music" -> Environment.DIRECTORY_MUSIC
        else -> error("Unsupported download location")
    }

    private fun publicDownloadDirectory(location: String): File =
        Environment.getExternalStoragePublicDirectory(storageDirectory(location))

    private fun selectCustomDownloadLocation(result: MethodChannel.Result) {
        if (customLocationResult != null) {
            result.error("PICKER_ACTIVE", "A folder picker is already open", null)
            return
        }

        customLocationResult = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
            }
            startActivityForResult(intent, CUSTOM_LOCATION_REQUEST_CODE)
        } catch (error: Exception) {
            customLocationResult = null
            result.error("PICKER_FAILED", error.message, error.toString())
        }
    }

    private fun customDownloadLocationDetails(): Map<String, String>? {
        val uri = customDownloadTreeUri() ?: return null
        val directory = DocumentFile.fromTreeUri(this, uri) ?: return null
        if (!directory.isDirectory || !directory.canWrite()) return null
        val name = directory.name?.takeIf { it.isNotBlank() } ?: "Selected folder"
        return mapOf(
            "uri" to uri.toString(),
            "path" to if (usesCustomGanneFolder()) "$name/Ganne" else name,
        )
    }

    private fun customDownloadDirectory(): DocumentFile {
        val uri = customDownloadTreeUri()
            ?: error("No custom download folder has been selected")
        val directory = DocumentFile.fromTreeUri(this, uri)
            ?: error("Unable to access the selected custom download folder")
        require(directory.isDirectory && directory.canWrite()) {
            "The selected custom download folder is no longer writable"
        }
        if (!usesCustomGanneFolder()) return directory
        rememberCustomGanneTree(uri)
        val existing = directory.findFile("Ganne")
        if (existing != null) {
            require(existing.isDirectory) { "The selected folder contains a file named Ganne" }
            return existing
        }
        return directory.createDirectory("Ganne")
            ?: error("Unable to create the Ganne folder")
    }

    private fun customDownloadTreeUri(): Uri? {
        val value = getSharedPreferences(packageName, MODE_PRIVATE)
            .getString(CUSTOM_TREE_URI_KEY, null)
            ?: return null
        return Uri.parse(value)
    }

    private fun persistCustomDownloadTree(uri: Uri) {
        val preferences = getSharedPreferences(packageName, MODE_PRIVATE)
        val trees = preferences.getStringSet(CUSTOM_TREE_URIS_KEY, emptySet())
            ?.toMutableSet()
            ?: mutableSetOf()
        val ganneTrees = preferences.getStringSet(CUSTOM_GANNE_TREE_URIS_KEY, null)
            ?.toMutableSet()
            ?: trees.toMutableSet()
        trees.add(uri.toString())
        preferences.edit()
            .putString(CUSTOM_TREE_URI_KEY, uri.toString())
            .putStringSet(CUSTOM_TREE_URIS_KEY, trees)
            .putStringSet(CUSTOM_GANNE_TREE_URIS_KEY, ganneTrees)
            .apply()
    }

    private fun usesCustomGanneFolder(): Boolean =
        getSharedPreferences(packageName, MODE_PRIVATE)
            .getBoolean(CUSTOM_USE_GANNE_FOLDER_KEY, false)

    private fun rememberCustomGanneTree(uri: Uri) {
        val preferences = getSharedPreferences(packageName, MODE_PRIVATE)
        val trees = preferences.getStringSet(CUSTOM_GANNE_TREE_URIS_KEY, emptySet())
            ?.toMutableSet()
            ?: mutableSetOf()
        if (trees.add(uri.toString())) {
            preferences.edit().putStringSet(CUSTOM_GANNE_TREE_URIS_KEY, trees).apply()
        }
    }

    private fun publishFile(
        sourcePath: String,
        displayName: String,
        relativeDirectory: String,
        mimeType: String,
        location: String,
    ): Map<String, String> {
        val source = File(sourcePath)
        require(source.isFile) { "Source file does not exist" }
        require(displayName.isNotBlank() && File(displayName).name == displayName) {
            "Invalid display name"
        }

        val directorySegments = relativeDirectory
            .replace('\\', '/')
            .split('/')
            .filter { it.isNotBlank() }
        require(directorySegments.none { it == "." || it == ".." }) {
            "Invalid relative directory"
        }
        if (location == "custom") {
            return publishCustom(source, displayName, directorySegments, mimeType)
        }
        val rootDirectory = storageDirectory(location)

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            publishScoped(source, displayName, directorySegments, mimeType, rootDirectory)
        } else {
            publishLegacy(source, displayName, directorySegments, mimeType, rootDirectory)
        }
    }

    private fun publishCustom(
        source: File,
        displayName: String,
        directorySegments: List<String>,
        mimeType: String,
    ): Map<String, String> {
        var directory = customDownloadDirectory()
        for (segment in directorySegments) {
            val existing = directory.findFile(segment)
            directory = when {
                existing == null -> directory.createDirectory(segment)
                    ?: error("Unable to create custom download directory")
                existing.isDirectory -> existing
                else -> error("Custom download path contains a file named $segment")
            }
        }

        val extensionIndex = displayName.lastIndexOf('.')
        val stem = if (extensionIndex > 0) displayName.substring(0, extensionIndex) else displayName
        val extension = if (extensionIndex > 0) displayName.substring(extensionIndex) else ""
        var suffix = 0
        var candidateName = displayName
        while (directory.findFile(candidateName) != null) {
            suffix++
            candidateName = "$stem ($suffix)$extension"
        }
        val target = directory.createFile(mimeType, candidateName)
            ?: error("Unable to create custom download file")

        try {
            contentResolver.openOutputStream(target.uri, "w")?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: error("Unable to open custom download output")
        } catch (error: Exception) {
            target.delete()
            throw error
        }
        rememberCustomPublishedFile(target.uri)
        return mapOf("path" to target.uri.toString(), "uri" to target.uri.toString())
    }

    private fun publishScoped(
        source: File,
        displayName: String,
        directorySegments: List<String>,
        mimeType: String,
        rootDirectory: String,
    ): Map<String, String> {
        val relativePath = buildString {
            append(rootDirectory)
            append("/Ganne")
            if (directorySegments.isNotEmpty()) {
                append('/')
                append(directorySegments.joinToString("/"))
            }
            append('/')
        }
        val collection = if (rootDirectory == Environment.DIRECTORY_DOWNLOADS) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else if (mimeType.startsWith("audio/")) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(collection, values)
            ?: error("Unable to create MediaStore entry")

        try {
            contentResolver.openOutputStream(uri, "w")?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: error("Unable to open MediaStore output")

            val completedValues = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            contentResolver.update(uri, completedValues, null, null)

            val fallbackPath = File(
                File(Environment.getExternalStoragePublicDirectory(rootDirectory), "Ganne"),
                (directorySegments + displayName).joinToString(File.separator),
            ).absolutePath
            val resolvedPath = contentResolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns.DATA),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            } ?: fallbackPath

            return mapOf("path" to resolvedPath, "uri" to uri.toString())
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }

    private fun publishLegacy(
        source: File,
        displayName: String,
        directorySegments: List<String>,
        mimeType: String,
        rootDirectory: String,
    ): Map<String, String> {
        val targetDirectory = directorySegments.fold(
            File(Environment.getExternalStoragePublicDirectory(rootDirectory), "Ganne"),
        ) {
                directory, segment -> File(directory, segment)
        }
        if (!targetDirectory.exists() && !targetDirectory.mkdirs()) {
            error("Unable to create public download directory")
        }

        val extensionIndex = displayName.lastIndexOf('.')
        val stem = if (extensionIndex > 0) displayName.substring(0, extensionIndex) else displayName
        val extension = if (extensionIndex > 0) displayName.substring(extensionIndex) else ""
        var target = File(targetDirectory, displayName)
        var suffix = 1
        while (target.exists()) {
            target = File(targetDirectory, "$stem ($suffix)$extension")
            suffix++
        }

        try {
            source.inputStream().use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
        } catch (error: Exception) {
            target.delete()
            throw error
        }
        MediaScannerConnection.scanFile(this, arrayOf(target.absolutePath), arrayOf(mimeType), null)
        return mapOf("path" to target.absolutePath, "uri" to "")
    }

    private fun deletePublishedFile(path: String): Boolean {
        if (path.startsWith("content://")) {
            val uri = Uri.parse(path)
            deletePlaybackCacheForUri(uri)
            val deleted = DocumentFile.fromSingleUri(this, uri)?.delete() ?: false
            if (deleted) forgetCustomPublishedFile(uri)
            return deleted
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val deleted = contentResolver.delete(
                    collection,
                    "${MediaStore.MediaColumns.DATA} = ?",
                    arrayOf(path),
                )
                if (deleted > 0) return true
            } catch (_: SecurityException) {
                // Fall back to direct deletion for files created by this app.
            }
        }

        val file = File(path)
        if (!file.exists()) return false
        val deleted = file.delete()
        if (deleted) MediaScannerConnection.scanFile(this, arrayOf(path), null, null)
        return deleted
    }

    private fun deleteAllPublishedFiles(): Int {
        clearPlaybackCache()
        var deleted = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            deleted += contentResolver.delete(
                collection,
                "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ? OR " +
                    "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?",
                arrayOf(
                    "${Environment.DIRECTORY_MUSIC}/Ganne/%",
                    "${Environment.DIRECTORY_DOWNLOADS}/Ganne/%",
                ),
            )
        } else {
            for (rootDirectory in listOf(Environment.DIRECTORY_MUSIC, Environment.DIRECTORY_DOWNLOADS)) {
                val directory = File(Environment.getExternalStoragePublicDirectory(rootDirectory), "Ganne")
                if (!directory.exists()) continue
                deleted += directory.walkTopDown().count { it.isFile }
                if (!directory.deleteRecursively()) {
                    error("Unable to delete public Ganne directory")
                }
                MediaScannerConnection.scanFile(this, arrayOf(directory.absolutePath), null, null)
            }
        }
        return deleted + deleteAllCustomPublishedFiles()
    }

    private fun deleteAllCustomPublishedFiles(): Int {
        val preferences = getSharedPreferences(packageName, MODE_PRIVATE)
        val publishedUris = preferences.getStringSet(CUSTOM_PUBLISHED_URIS_KEY, emptySet())
            ?.toMutableSet()
            ?: mutableSetOf()
        var deleted = 0
        for (publishedUri in publishedUris.toList()) {
            val document = DocumentFile.fromSingleUri(this, Uri.parse(publishedUri))
            if (document?.delete() == true) {
                deleted++
                publishedUris.remove(publishedUri)
            }
        }
        preferences.edit().putStringSet(CUSTOM_PUBLISHED_URIS_KEY, publishedUris).apply()

        val ganneTrees = preferences.getStringSet(CUSTOM_GANNE_TREE_URIS_KEY, null)
            ?: preferences.getStringSet(CUSTOM_TREE_URIS_KEY, emptySet())
            ?: emptySet()
        for (treeUri in ganneTrees) {
            val root = DocumentFile.fromTreeUri(this, Uri.parse(treeUri)) ?: continue
            val ganneDirectory = root.findFile("Ganne") ?: continue
            deleted += pruneEmptyDirectories(
                ganneDirectory,
                isDirectory = { it.isDirectory },
                listChildren = { it.listFiles().toList() },
                deleteDirectory = { it.delete() },
            )
        }
        return deleted
    }

    private fun rememberCustomPublishedFile(uri: Uri) {
        val preferences = getSharedPreferences(packageName, MODE_PRIVATE)
        val files = preferences.getStringSet(CUSTOM_PUBLISHED_URIS_KEY, emptySet())
            ?.toMutableSet()
            ?: mutableSetOf()
        if (files.add(uri.toString())) {
            preferences.edit().putStringSet(CUSTOM_PUBLISHED_URIS_KEY, files).apply()
        }
    }

    private fun forgetCustomPublishedFile(uri: Uri) {
        val preferences = getSharedPreferences(packageName, MODE_PRIVATE)
        val files = preferences.getStringSet(CUSTOM_PUBLISHED_URIS_KEY, emptySet())
            ?.toMutableSet()
            ?: return
        if (files.remove(uri.toString())) {
            preferences.edit().putStringSet(CUSTOM_PUBLISHED_URIS_KEY, files).apply()
        }
    }

    private fun deletePlaybackCacheForUri(uri: Uri) {
        val directory = File(cacheDir, "ganne_playback")
        val prefix = "${uri.toString().hashCode()}_"
        directory.listFiles()?.forEach { file ->
            if (file.name.startsWith(prefix)) file.delete()
        }
    }

    private fun clearPlaybackCache() {
        val directory = File(cacheDir, "ganne_playback")
        if (directory.exists() && !directory.deleteRecursively()) {
            error("Unable to clear the playback cache")
        }
    }

    private fun openDocument(uri: Uri): Boolean {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, contentResolver.getType(uri) ?: "application/octet-stream")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        if (intent.resolveActivity(packageManager) == null) return false
        startActivity(Intent.createChooser(intent, "Open file"))
        return true
    }

    private fun copyDocumentForPlayback(uri: Uri): String {
        val displayName = DocumentFile.fromSingleUri(this, uri)?.name
            ?.takeIf { it.isNotBlank() }
            ?: "audio"
        val cacheDirectory = File(cacheDir, "ganne_playback")
        if (!cacheDirectory.exists() && !cacheDirectory.mkdirs()) {
            error("Unable to create playback cache directory")
        }
        val target = File(cacheDirectory, "${uri.toString().hashCode()}_${File(displayName).name}")
        contentResolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { output -> input.copyTo(output) }
        } ?: error("Unable to open custom download for playback")
        return target.absolutePath
    }
}
