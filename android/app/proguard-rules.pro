# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep WorkManager and Room database classes from being stripped or obfuscated by R8
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(...);
}
-dontwarn androidx.work.**

# Google Mobile Ads (AdMob)
-keep public class com.google.android.gms.ads.** { *; }
-keep public class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# In-App Purchase (Google Play Billing)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Google Play Core / Deferred Components
-dontwarn com.google.android.play.core.**

# SQFLite Database
-keep class com.tekartik.sqflite.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Vibration
-keep class com.benjaminabel.vibration.** { *; }

# Google Play Games Services
-keep class com.google.android.gms.games.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.games.**



