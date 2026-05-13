# ALGOPA ProGuard/R8 룰
#
# Flutter 기본은 flutter.gradle이 자동으로 io.flutter.* 보존하지만
# 명시적으로 추가 + Supabase/HTTP 클라이언트 호환 룰 보강.

# ===== Flutter =====
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ===== reflection/serialization 공통 =====
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ===== HTTP (OkHttp/okio) — supabase_flutter 의존성 =====
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# ===== Native libs (Pretendard 폰트 등 assets 처리) =====
-keep class com.google.android.material.** { *; }

# ===== Coroutines (kotlinx) — 일부 Flutter plugin 사용 =====
-dontwarn kotlinx.coroutines.**
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# ===== shared_preferences / url_launcher / flutter_dotenv =====
# Flutter Plugin 시스템이 자동 처리하나 미사용 클래스 제거 시 발생 가능한 경고 억제
-dontwarn io.flutter.plugins.**
