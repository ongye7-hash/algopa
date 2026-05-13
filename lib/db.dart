import 'package:supabase_flutter/supabase_flutter.dart';

class Brand {
  final String id;
  final String name;
  Brand({required this.id, required this.name});
  factory Brand.fromJson(Map<String, dynamic> j) =>
      Brand(id: j['id'] as String, name: j['name'] as String);
}

class Discount {
  final String id;
  final String provider;
  final String type;
  final String? rate;
  final String? limitAmount;
  final String? conditions;
  final String? sourceUrl;
  Discount({
    required this.id,
    required this.provider,
    required this.type,
    this.rate,
    this.limitAmount,
    this.conditions,
    this.sourceUrl,
  });
  factory Discount.fromJson(Map<String, dynamic> j) => Discount(
        id: j['id'] as String,
        provider: j['provider'] as String,
        type: j['type'] as String,
        rate: j['rate'] as String?,
        limitAmount: j['limit_amount'] as String?,
        conditions: j['conditions'] as String?,
        sourceUrl: j['source_url'] as String?,
      );
}

final _client = Supabase.instance.client;

Future<List<Brand>> searchBrands(String query) async {
  final q = query.trim();
  if (q.isEmpty) return [];
  final rows = await _client
      .from('brands')
      .select('id, name')
      .ilike('name', '%$q%')
      .order('name', ascending: true)
      .limit(20);
  return (rows as List)
      .map((r) => Brand.fromJson(r as Map<String, dynamic>))
      .toList();
}

Future<List<Brand>> topBrandsForRecommendation({int limit = 5}) async {
  final rows = await _client
      .from('brands')
      .select('id, name')
      .order('name', ascending: true)
      .limit(limit);
  return (rows as List)
      .map((r) => Brand.fromJson(r as Map<String, dynamic>))
      .toList();
}

Future<List<Discount>> discountsByBrand(String brandId) async {
  final rows = await _client
      .from('discounts')
      .select('id, provider, type, rate, limit_amount, conditions, source_url')
      .eq('brand_id', brandId)
      .order('id', ascending: true);
  return (rows as List)
      .map((r) => Discount.fromJson(r as Map<String, dynamic>))
      .toList();
}

const List<String> kBrandCategories = [
  '외식', '카페', '쇼핑/생활', '문화/레저', '미용/생활서비스',
];

Future<void> submitBrandRequest({
  required String brandName,
  String? category,
  String? contact,
}) async {
  final c = contact?.trim();
  await _client.from('brand_requests').insert({
    'brand_name': brandName.trim(),
    'category': category,
    'contact': (c == null || c.isEmpty) ? null : c,
  });
}

/// 검색 로깅 — fire-and-forget. 실패 시 silent (사용자 UX 차단 X).
/// 0005_search_logs 마이그레이션 미적용 시 PostgrestException → catch에서 무시.
Future<void> logSearch({
  required String query,
  required int resultCount,
  String? matchedBrandId,
}) async {
  try {
    await _client.from('search_logs').insert({
      'query': query.trim(),
      'result_count': resultCount,
      'matched_brand_id': matchedBrandId,
    });
  } catch (_) {
    // 로깅 실패는 사용자 경험에 영향 없도록 무시.
  }
}
