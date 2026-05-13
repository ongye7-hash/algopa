import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'db.dart';
import 'error.dart';
import 'theme.dart';

/// rate 텍스트(자유 서술)에서 첫 정수만 추출 — 정렬용.
/// 콤마 제거 후 매칭. 추출 실패는 -1 (정렬 시 맨 뒤).
/// 의미적 할인율과 정확히 같진 않지만(예: "별 12개 적립" → 12) MVP fallback.
int _extractFirstNumber(String? text) {
  if (text == null) return -1;
  final cleaned = text.replaceAll(',', '');
  final m = RegExp(r'\d+').firstMatch(cleaned);
  return m == null ? -1 : (int.tryParse(m.group(0)!) ?? -1);
}

final _telcoRe = RegExp(r'SKT|KT|LG U?\+?|통신사');

/// 할인 카테고리 ranking — 작을수록 위에 노출.
/// 1: 카드사  2: 통신사  3: 브랜드 멤버십  4: 쿠폰  5: 기타
/// 첫 매치 우선 (예: "카드사 시즌 쿠폰" → 카드사 1, 쿠폰 4 X)
int _categoryRank(Discount d) {
  final p = d.provider;
  final t = d.type;
  if (p.contains('카드') || t.contains('카드')) return 1;
  if (_telcoRe.hasMatch(p) || t.contains('통신사')) return 2;
  if (p.startsWith('브랜드')) return 3;
  if (t.contains('쿠폰')) return 4;
  return 5;
}

Future<void> _openSourceUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
  }
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('브라우저를 열 수 없어 URL을 복사했습니다'),
      duration: Duration(seconds: 2),
    ),
  );
}

class ResultScreen extends StatefulWidget {
  final Brand brand;
  const ResultScreen({super.key, required this.brand});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<List<Discount>> _future;

  @override
  void initState() {
    super.initState();
    _future = discountsByBrand(widget.brand.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.brand.name)),
      body: FutureBuilder<List<Discount>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      humanizeError(snap.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = discountsByBrand(widget.brand.id);
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }
          final list = List<Discount>.from(snap.data ?? [])
            ..sort((a, b) {
              // 1차: 카테고리(카드사 → 통신사 → 멤버십 → 쿠폰 → 기타)
              final ca = _categoryRank(a);
              final cb = _categoryRank(b);
              if (ca != cb) return ca.compareTo(cb); // ASC
              // 2차: 그룹 내 할인 큰 순
              final ra = _extractFirstNumber(a.rate);
              final rb = _extractFirstNumber(b.rate);
              if (ra != rb) return rb.compareTo(ra); // DESC
              // 3차: provider 알파벳순
              return a.provider.compareTo(b.provider);
            });
          if (list.isEmpty) {
            return const Center(child: Text('등록된 할인 정보가 없음'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '총 ${list.length}건',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _DiscountCard(d: list[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  final Discount d;
  const _DiscountCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.provider,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    d.type,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if ((d.rate ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                d.rate!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
            if ((d.limitAmount ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '한도: ${d.limitAmount}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if ((d.conditions ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '조건: ${d.conditions}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if ((d.sourceUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _openSourceUrl(context, d.sourceUrl!);
                },
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: d.sourceUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('출처 URL 복사됨 (길게 눌러 복사)'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '출처: ${d.sourceUrl}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
