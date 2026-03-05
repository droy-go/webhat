package com.webhat.storypack

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Custom MainActivity for WebHat StoryPack
 * 
 * Features:
 * - Uses cached Flutter engine for faster startup
 * - Handles deep links and intents
 * - Method channel for native communication
 * - Lifecycle optimization
 */
class MainActivity : FlutterFragmentActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.webhat.storypack/native"
        const val EXTRA_WEBHAT_FILE = "extra_webhat_file"
    }
    
    private var methodChannel: MethodChannel? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Use cached engine if available
        val cachedEngine = WebHatApplication.instance.getFlutterEngine()
        if (cachedEngine != null) {
            Log.d(TAG, "Using cached Flutter engine")
        }
        
        super.onCreate(savedInstanceState)
        
        // Handle intent extras
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    /**
     * Configure Flutter engine with custom settings
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup method channel for native communication
        setupMethodChannel(flutterEngine)
        
        Log.d(TAG, "Flutter engine configured")
    }
    
    /**
     * Setup method channel for Flutter <-> Native communication
     */
    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    result.success(BuildConfig.VERSION_NAME)
                }
                "getBuildNumber" -> {
                    result.success(BuildConfig.VERSION_CODE)
                }
                "clearCache" -> {
                    WebHatApplication.instance.clearCaches()
                    result.success(true)
                }
                "getCacheSize" -> {
                    val cacheSize = calculateCacheSize()
                    result.success(cacheSize)
                }
                "shareFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        shareFile(filePath)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                    }
                }
                "openFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        openExternalFile(filePath)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Handle incoming intents (deep links, file opens)
     */
    private fun handleIntent(intent: Intent?) {
        intent?.let {
            when (it.action) {
                Intent.ACTION_VIEW -> {
                    // Handle .webhat file opened from file manager
                    val uri = it.data
                    if (uri != null) {
                        val filePath = uri.path
                        if (filePath?.endsWith(".webhat") == true) {
                            // Pass to Flutter
                            methodChannel?.invokeMethod("onWebHatFileOpened", filePath)
                        }
                    }
                }
                Intent.ACTION_SEND -> {
                    // Handle shared files
                    val uri = it.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                    uri?.let { sharedUri ->
                        val filePath = sharedUri.path
                        methodChannel?.invokeMethod("onWebHatFileShared", filePath)
                    }
                }
            }
        }
    }
    
    /**
     * Calculate total cache size in bytes
     */
    private fun calculateCacheSize(): Long {
        var size: Long = 0
        
        // App cache
        cacheDir?.let { dir ->
            size += getFolderSize(dir)
        }
        
        // External cache
        externalCacheDir?.let { dir ->
            size += getFolderSize(dir)
        }
        
        return size
    }
    
    /**
     * Get size of a folder recursively
     */
    private fun getFolderSize(folder: java.io.File): Long {
        var size: Long = 0
        folder.listFiles()?.forEach { file ->
            size += if (file.isDirectory) {
                getFolderSize(file)
            } else {
                file.length()
            }
        }
        return size
    }
    
    /**
     * Share a file using Android's share sheet
     */
    private fun shareFile(filePath: String) {
        val file = java.io.File(filePath)
        if (!file.exists()) return
        
        val uri = androidx.core.content.FileProvider.getUriForFile(
            this,
            "${packageName}.fileprovider",
            file
        )
        
        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            type = "application/zip"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        
        startActivity(Intent.createChooser(shareIntent, "Share WebHat Story"))
    }
    
    /**
     * Open a file with external app
     */
    private fun openExternalFile(filePath: String) {
        val file = java.io.File(filePath)
        if (!file.exists()) return
        
        val uri = androidx.core.content.FileProvider.getUriForFile(
            this,
            "${packageName}.fileprovider",
            file
        )
        
        val openIntent = Intent().apply {
            action = Intent.ACTION_VIEW
            setDataAndType(uri, "application/zip")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        
        try {
            startActivity(openIntent)
        } catch (e: Exception) {
            Log.e(TAG, "No app found to open file", e)
        }
    }
    
    /**
     * Provide cached engine for faster startup
     */
    override fun getCachedEngineId(): String? {
        return WebHatApplication.instance.getFlutterEngine()?.let {
            return "webhat_engine"
        }
    }
    
    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
