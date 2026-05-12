import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자에게 보여줄 한국어 에러 메시지로 변환.
/// SocketException, TimeoutException, PostgrestException 분기.
String humanizeError(Object e) {
  if (e is SocketException) {
    return '인터넷 연결을 확인해주세요';
  }
  if (e is TimeoutException) {
    return '응답이 지연됩니다. 잠시 후 다시 시도해주세요';
  }
  if (e is PostgrestException) {
    final code = e.code ?? '?';
    return '서버 오류 ($code). 잠시 후 다시 시도해주세요';
  }
  return '일시적 오류입니다. 잠시 후 다시 시도해주세요';
}
