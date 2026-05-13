import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db.dart';
import 'error.dart';
import 'request_screen.dart';
import 'result_screen.dart';

const _kRecentKey = 'recent_searches';
const _kRecentMax = 10;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Brand> _results = [];
  List<Brand> _recommended = [];
  List<String> _recent = [];
  bool _searching = false;
  bool _searchedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_kRecentKey) ?? [];
    try {
      final rec = await topBrandsForRecommendation();
      if (!mounted) return;
      setState(() {
        _recent = recent;
        _recommended = rec;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _recent = recent);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeError(e)),
          action: SnackBarAction(
            label: '다시 시도',
            onPressed: _loadInitialData,
          ),
        ),
      );
    }
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(text);
    });
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searchedOnce = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await searchBrands(q);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        _searchedOnce = true;
      });
      // fire-and-forget: 익명 집계 (실패 silent)
      unawaited(logSearch(query: q, resultCount: results.length));
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeError(e)),
          action: SnackBarAction(
            label: '다시 시도',
            onPressed: () => _runSearch(q),
          ),
        ),
      );
    }
  }

  Future<void> _saveRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_kRecentKey) ?? [];
    current.remove(q);
    current.insert(0, q);
    if (current.length > _kRecentMax) {
      current.removeRange(_kRecentMax, current.length);
    }
    await prefs.setStringList(_kRecentKey, current);
    if (!mounted) return;
    setState(() => _recent = current);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentKey);
    if (!mounted) return;
    setState(() => _recent = []);
  }

  void _openBrand(Brand b) {
    final qToSave = _ctrl.text.trim().isEmpty ? b.name : _ctrl.text.trim();
    _saveRecent(qToSave);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(brand: b)),
    );
  }

  void _setQuery(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: q.length),
    );
    _onChanged(q);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _ctrl.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('algopa — 매장 할인 검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '오늘 어디가세요? 예: 스타벅스, 아웃백',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          _onChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                _runSearch(v);
              },
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: hasQuery ? _buildResults() : _buildIdleState(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searching && _results.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_searchedOnce && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '"${_ctrl.text}"에 대한 결과 없음',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '다른 검색어를 시도하거나\n없는 매장을 요청해주세요',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestScreen(prefillName: _ctrl.text.trim()),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('없는 매장 요청하기'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final b = _results[i];
        return ListTile(
          title: Text(b.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openBrand(b),
        );
      },
    );
  }

  Widget _buildIdleState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                '최근 검색',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearRecent,
                child: const Text('지우기'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _recent
                .map((q) => ActionChip(
                      label: Text(q),
                      onPressed: () => _setQuery(q),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          '추천 검색',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (_recommended.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('로딩 중...', style: TextStyle(color: Colors.grey)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _recommended
                .map((b) => ActionChip(
                      label: Text(b.name),
                      onPressed: () => _setQuery(b.name),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
