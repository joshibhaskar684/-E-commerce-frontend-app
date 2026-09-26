import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/home_data.dart';
import '../../services/product_service.dart';
import '../products/product_list_screen.dart';

/// Search with live suggestions (website: Navbar/components/SearchBar.jsx):
/// typing waits 400 ms, then calls GET /products/suggestions?q=…
/// Submitting opens the results from GET /products/page/query/main.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _recentKey = 'recent_searches';
  static const _debounce = Duration(milliseconds: 400);

  final _controller = TextEditingController();
  final _service = ProductService();
  Timer? _timer;
  List<String> _suggestions = const [];
  List<String> _recent = const [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _recent = p.getStringList(_recentKey) ?? const []);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    setState(() {});
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }
    _timer = Timer(_debounce, () async {
      setState(() => _loadingSuggestions = true);
      final result = await _service.getSuggestions(value);
      if (!mounted || _controller.text.trim() != value.trim()) return;
      setState(() {
        _suggestions = result;
        _loadingSuggestions = false;
      });
    });
  }

  Future<void> _submit(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [q, ..._recent.where((r) => r.toLowerCase() != q.toLowerCase())].take(8).toList();
    await prefs.setStringList(_recentKey, updated);
    if (!mounted) return;
    setState(() => _recent = updated);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProductListScreen.search(query: q)),
    );
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    setState(() => _recent = const []);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final typing = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Search for products, brands and categories…',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: typing
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (typing) ...[
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Search for '),
                TextSpan(text: '"${_controller.text.trim()}"', style: const TextStyle(fontWeight: FontWeight.w700)),
              ])),
              trailing: const Icon(Icons.north_west_rounded, size: 18),
              onTap: () => _submit(_controller.text),
            ),
            if (_loadingSuggestions) const LinearProgressIndicator(minHeight: 2),
            for (final s in _suggestions)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                onTap: () => _submit(s),
              ),
          ] else ...[
            if (_recent.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(child: Text('Recent searches', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    TextButton(onPressed: _clearRecent, child: const Text('Clear')),
                  ],
                ),
              ),
              for (final r in _recent)
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: Text(r),
                  trailing: const Icon(Icons.north_west_rounded, size: 18),
                  onTap: () => _submit(r),
                ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Popular searches', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in HomeData.popularSearches)
                    ActionChip(label: Text(p), onPressed: () => _submit(p)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
