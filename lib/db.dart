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
      .order('provider', ascending: true);
  return (rows as List)
      .map((r) => Discount.fromJson(r as Map<String, dynamic>))
      .toList();
}
