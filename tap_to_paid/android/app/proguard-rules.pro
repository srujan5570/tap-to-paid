# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Unity Ads
-keepattributes SourceFile,LineNumberTable
-keepattributes JavascriptInterface
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }

# Keep your application class
-keep class com.taptopaid.tap_to_paid.** { *; }

# Multidex
-keep class androidx.multidex.** { *; }

# Play Store
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep R8 rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exception

# Keep methods that are accessed via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# For crash reporting and analytics (if you add them later)
-keepattributes *Annotation*
-keepattributes Exception
-keepattributes Signature
-keepattributes InnerClasses 