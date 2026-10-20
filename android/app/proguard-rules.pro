# shared_preferences_android calls its Kotlin API from Dart via JNI, which
# R8 can't see – without this the release build crashes on start (#281).
-keep class io.flutter.plugins.sharedpreferences.** { *; }
