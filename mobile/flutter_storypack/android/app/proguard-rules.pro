# WebHat StoryPack ProGuard Rules

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Archive library (for ZIP handling)
-keep class org.apache.commons.compress.** { *; }
-dontwarn org.apache.commons.compress.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application class
-keep class com.webhat.storypack.WebHatApplication { *; }
-keep class com.webhat.storypack.MainActivity { *; }

# Keep method channel handlers
-keep class com.webhat.storypack.** { *; }

# AudioPlayers
-keep class xyz.luan.audioplayers.** { *; }

# FilePicker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ImagePicker
-keep class io.flutter.plugins.imagepicker.** { *; }

# PathProvider
-keep class io.flutter.plugins.pathprovider.** { *; }

# SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# PermissionHandler
-keep class com.baseflow.permissionhandler.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# WindowManager (desktop)
-keep class com.onebytecode.window_manager.** { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
