# ProGuard rules for Smart Employee app

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Location services
-keep class com.google.android.gms.location.** { *; }

# Smart Employee native code
-keep class com.example.smart_employee.** { *; }

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.example.smart_employee.**$$serializer { *; }
-keepclassmembers class com.example.smart_employee.** {
    *** Companion;
}
-keepclasseswithmembers class com.example.smart_employee.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
