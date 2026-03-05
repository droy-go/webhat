package com.webhat.storypack

import android.app.Application
import android.content.Context
import android.os.Build
import android.os.StrictMode
import android.util.Log
import androidx.multidex.MultiDex
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.view.FlutterMain

/**
 * Custom Application class for WebHat StoryPack
 * 
 * Features:
 * - Pre-warmed Flutter engine for faster startup
 * - Memory management optimizations
 * - StrictMode for development debugging
 * - Custom cache configuration
 */
class WebHatApplication : Application() {
    
    companion object {
        private const val TAG = "WebHatApplication"
        private const val ENGINE_ID = "webhat_engine"
        
        @JvmStatic
        lateinit var instance: WebHatApplication
            private set
    }
    
    private var flutterEngine: FlutterEngine? = null
    
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        // MultiDex support for older Android versions
        MultiDex.install(this)
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        // Initialize Flutter
        FlutterMain.startInitialization(this)
        
        // Setup strict mode in debug builds
        if (BuildConfig.DEBUG) {
            setupStrictMode()
        }
        
        // Pre-warm Flutter engine for faster UI rendering
        prewarmFlutterEngine()
        
        // Initialize custom cache
        initializeCache()
        
        Log.d(TAG, "WebHatApplication initialized")
    }
    
    /**
     * Setup StrictMode for detecting performance issues in debug builds
     */
    private fun setupStrictMode() {
        StrictMode.setThreadPolicy(
            StrictMode.ThreadPolicy.Builder()
                .detectDiskReads()
                .detectDiskWrites()
                .detectNetwork()
                .penaltyLog()
                .build()
        )
        
        StrictMode.setVmPolicy(
            StrictMode.VmPolicy.Builder()
                .detectLeakedSqlLiteObjects()
                .detectLeakedClosableObjects()
                .penaltyLog()
                .build()
        )
    }
    
    /**
     * Pre-warm Flutter engine to reduce initial startup time
     */
    private fun prewarmFlutterEngine() {
        try {
            flutterEngine = FlutterEngine(this)
            
            // Configure Dart entrypoint
            flutterEngine?.dartExecutor?.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            
            // Cache the engine for reuse
            FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
            
            Log.d(TAG, "Flutter engine pre-warmed successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to pre-warm Flutter engine", e)
        }
    }
    
    /**
     * Initialize custom cache configuration
     */
    private fun initializeCache() {
        // Configure image cache size based on device memory
        val maxMemory = (Runtime.getRuntime().maxMemory() / 1024).toInt()
        val cacheSize = maxMemory / 8
        
        // This will be used by the Flutter app's image caching
        val prefs = getSharedPreferences("webhat_cache", Context.MODE_PRIVATE)
        prefs.edit().putInt("cache_size", cacheSize).apply()
    }
    
    /**
     * Get the cached Flutter engine
     */
    fun getFlutterEngine(): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(ENGINE_ID)
    }
    
    /**
     * Clear all caches
     */
    fun clearCaches() {
        try {
            // Clear Flutter engine cache
            flutterEngine?.let { engine ->
                // Clear image cache
                // Note: This would need to be implemented in Flutter side
            }
            
            // Clear app cache
            cacheDir?.deleteRecursively()
            externalCacheDir?.deleteRecursively()
            
            Log.d(TAG, "Caches cleared successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear caches", e)
        }
    }
    
    override fun onLowMemory() {
        super.onLowMemory()
        Log.w(TAG, "Low memory detected, clearing caches")
        clearCaches()
    }
    
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        when (level) {
            TRIM_MEMORY_RUNNING_CRITICAL,
            TRIM_MEMORY_RUNNING_LOW,
            TRIM_MEMORY_RUNNING_MODERATE -> {
                Log.w(TAG, "Memory trim level: $level")
            }
            TRIM_MEMORY_UI_HIDDEN -> {
                // UI is hidden, can clear some caches
            }
            TRIM_MEMORY_BACKGROUND,
            TRIM_MEMORY_MODERATE,
            TRIM_MEMORY_COMPLETE -> {
                Log.w(TAG, "Aggressive memory trim level: $level, clearing caches")
                clearCaches()
            }
        }
    }
}
