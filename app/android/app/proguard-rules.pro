# google_mlkit_text_recognition's Kotlin bridge references TextRecognizerOptions
# classes for every script (Chinese/Japanese/Korean/Devanagari) unconditionally,
# but each script's actual class is only on the classpath if the consuming app
# adds it as a real dependency (see build.gradle.kts). This app only bundles
# Latin (default) and Devanagari (DR-006) — Chinese/Japanese/Korean are
# deliberately not included, so R8 can't resolve those references at all and
# fails outright without these lines. The app never calls those code paths
# (TextRecognitionScript.chinese/japanese/korean are never used), so it's safe
# to tell R8 not to worry about them rather than bundle scripts we don't need.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
