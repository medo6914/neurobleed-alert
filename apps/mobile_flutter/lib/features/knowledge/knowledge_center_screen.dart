import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'providers/knowledge_provider.dart';

class KnowledgeCenterScreen extends ConsumerStatefulWidget {
  const KnowledgeCenterScreen({super.key});

  @override
  ConsumerState<KnowledgeCenterScreen> createState() => _KnowledgeCenterScreenState();
}

class _KnowledgeCenterScreenState extends ConsumerState<KnowledgeCenterScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(knowledgeProvider.notifier).search(query, category: _selectedCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(knowledgeProvider);
    final categories = ref.watch(knowledgeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Center'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medical knowledge...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(knowledgeProvider.notifier).clear();
                            },
                          )
                        : null,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _selectedCategory == null,
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          if (_searchController.text.isNotEmpty) _performSearch();
                        },
                      ),
                      ...categories.map((cat) => _CategoryChip(
                            label: cat[0].toUpperCase() + cat.substring(1),
                            selected: _selectedCategory == cat,
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              if (_searchController.text.isNotEmpty) _performSearch();
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(KnowledgeSearchState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: AppLoading());
    }

    if (state.error != null) {
      return AppErrorState(
        title: 'Search Error',
        message: state.error!,
        onRetry: _performSearch,
      );
    }

    if (state.query == null) {
      return AppEmptyState(
        icon: Icons.menu_book,
        title: 'Knowledge Center',
        message: 'Search medical guidelines, research, and clinical knowledge.',
      );
    }

    if (state.results.isEmpty && state.semanticResults.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: 'No Results',
        message: 'No knowledge entries found for "${state.query}"',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (state.query != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Found ${state.total} result(s) in ${state.queryTimeMs.toStringAsFixed(0)}ms',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        if (state.semanticResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text('AI Semantic Matches',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                )),
          ),
          ...state.semanticResults.map((result) => _KnowledgeCard(
                result: result,
                isSemantic: true,
              )),
        ],
        if (state.results.isNotEmpty && state.semanticResults.isNotEmpty)
          const Divider(height: 24),
        if (state.results.isNotEmpty) ...[
          if (state.semanticResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Database Results',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ...state.results.map((result) => _KnowledgeCard(
                result: result,
                isSemantic: false,
              )),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isSemantic;

  const _KnowledgeCard({required this.result, required this.isSemantic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = result['title'] as String? ?? 'Untitled';
    final content = result['content'] as String? ?? '';
    final category = result['category'] as String? ?? 'general';
    final source = result['source'] as String? ?? '';
    final score = (result['score'] as num?)?.toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          isSemantic ? Icons.psychology : Icons.article,
          color: isSemantic ? theme.colorScheme.primary : Colors.grey.shade600,
          size: 20,
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            _SmallBadge(label: category),
            if (score != null) ...[
              const SizedBox(width: 4),
              _SmallBadge(
                label: '${(score * 100).round()}%',
                color: score > 0.7 ? Colors.green : score > 0.4 ? Colors.orange : Colors.grey,
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: theme.textTheme.bodySmall,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                if (source.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Source: $source',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const _SmallBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color ?? Colors.grey.shade700),
      ),
    );
  }
}
