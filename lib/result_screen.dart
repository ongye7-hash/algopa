import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db.dart';

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
                padding: const EdgeInsets.all(16),
                child: Text('할인 정보 로드 실패: ${snap.error}'),
              ),
            );
          }
          final list = snap.data ?? [];
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
                          fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    d.provider,
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if ((d.rate ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(d.rate!),
            ],
            if ((d.limitAmount ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '한도: ${d.limitAmount}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            if ((d.conditions ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '조건: ${d.conditions}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            if ((d.sourceUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: d.sourceUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('출처 URL 복사됨'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(
                  '출처: ${d.sourceUrl}',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
