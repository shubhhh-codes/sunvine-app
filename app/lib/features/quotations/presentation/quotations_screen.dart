import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import 'controllers/quotations_controller.dart';
import 'widgets/quotation_card_widget.dart';

/// Presentation screen for viewing and searching consumer solar proposals.
class QuotationsScreen extends StatefulWidget {
  final VoidCallback onNewQuote;
  final QuotationsController? controller;

  const QuotationsScreen({
    super.key,
    required this.onNewQuote,
    this.controller,
  });

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  late final QuotationsController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller!;
    if (_controller.status == QuotationsStatus.initial) {
      _controller.loadQuotations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Quotations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.loadQuotations(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              SunInput(
                controller: _searchController,
                hintText: 'Search by customer name, phone, or SV ID...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                      )
                    : null,
                onChanged: (val) => _controller.setSearchQuery(val),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (_controller.isLoading && _controller.filteredQuotations.isEmpty) {
                      return const SunLoadingIndicator(message: 'Loading quotations...');
                    }

                    if (_controller.status == QuotationsStatus.error && _controller.filteredQuotations.isEmpty) {
                      return SunErrorView(
                        message: _controller.errorMessage ?? 'Unable to load quotations',
                        onRetry: () => _controller.loadQuotations(),
                      );
                    }

                    final quotes = _controller.filteredQuotations;

                    if (quotes.isEmpty) {
                      return SunEmptyState(
                        icon: Icons.search_off_rounded,
                        title: _controller.searchQuery.isNotEmpty
                            ? 'No matches found'
                            : 'No quotations available',
                        description: _controller.searchQuery.isNotEmpty
                            ? 'Try searching with another keyword.'
                            : 'Click "+ New Quote" to generate your first proposal.',
                        actionLabel: _controller.searchQuery.isNotEmpty ? null : 'Create Quotation',
                        onAction: _controller.searchQuery.isNotEmpty ? null : widget.onNewQuote,
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.emerald,
                      backgroundColor: AppColors.surface,
                      onRefresh: () => _controller.loadQuotations(),
                      child: ListView.separated(
                        itemCount: quotes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          return QuotationCardWidget(quotation: quote);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
