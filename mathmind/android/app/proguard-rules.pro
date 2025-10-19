# ProGuard/R8 rules for MathMind

# Suppress warnings for optional ML Kit text recognition language models
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# Keep the primary TextRecognizer APIs and Latin model classes
-keep class com.google.mlkit.vision.text.TextRecognizer { *; }
-keep class com.google.mlkit.vision.text.latin.** { *; }

# (Optional) Reduce noisy warnings from ML Kit internals
-dontwarn com.google.mlkit.**