import 'package:breweries_for_the_world/core/l10n/app_localizations.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/domain/entities/brewery.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_bloc.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_event.dart';
import 'package:breweries_for_the_world/features/nearby_breweries/presentation/bloc/brewery_catalog_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BreweryCatalogPage extends StatelessWidget {
  const BreweryCatalogPage({super.key, required this.onBrewerySelected});

  final ValueChanged<Brewery> onBrewerySelected;

  static const _loadAheadExtent = 400.0;
  static const _breweryTypes = [
    'micro',
    'nano',
    'regional',
    'brewpub',
    'large',
    'planning',
    'bar',
    'contract',
    'closed',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<BreweryCatalogBloc>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogTitle)),
      body: BlocBuilder<BreweryCatalogBloc, BreweryCatalogState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _CatalogSearchField(
                    query: state.query,
                    hint: l10n.catalogSearchHint,
                    clearLabel: l10n.clearSearch,
                    onChanged: (query) =>
                        bloc.add(BreweryCatalogSearchChanged(query)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<BreweryCatalogSortOrder>(
                          key: const ValueKey('brewery-catalog-sort'),
                          initialValue: state.sortOrder,
                          decoration: InputDecoration(
                            labelText: l10n.catalogSort,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: BreweryCatalogSortOrder.defaultOrder,
                              child: Text(l10n.catalogSortDefault),
                            ),
                            DropdownMenuItem(
                              value: BreweryCatalogSortOrder.nameAscending,
                              child: Text(l10n.catalogSortNameAscending),
                            ),
                            DropdownMenuItem(
                              value: BreweryCatalogSortOrder.nameDescending,
                              child: Text(l10n.catalogSortNameDescending),
                            ),
                            DropdownMenuItem(
                              value: BreweryCatalogSortOrder.cityAscending,
                              child: Text(l10n.catalogSortCity),
                            ),
                            DropdownMenuItem(
                              value: BreweryCatalogSortOrder.typeAscending,
                              child: Text(l10n.catalogSortType),
                            ),
                          ],
                          onChanged: (sortOrder) {
                            if (sortOrder != null) {
                              bloc.add(BreweryCatalogSortChanged(sortOrder));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        key: const ValueKey('brewery-catalog-filter-button'),
                        tooltip: l10n.catalogFilters,
                        onPressed: () => _showFilters(context, state),
                        icon: Badge(
                          isLabelVisible: state.activeTypes.isNotEmpty,
                          label: Text('${state.activeTypes.length}'),
                          child: const Icon(Icons.filter_list),
                        ),
                      ),
                    ],
                  ),
                  if (state.activeTypes.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.catalogFilterCount(state.activeTypes.length),
                          key: const ValueKey('brewery-catalog-filter-count'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (state.isLoading && state.breweries.isNotEmpty)
              const LinearProgressIndicator(),
            Expanded(child: _buildResults(context, state, bloc, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    BreweryCatalogState state,
    BreweryCatalogBloc bloc,
    AppLocalizations l10n,
  ) {
    if (state.isLoading && state.breweries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.breweries.isEmpty) {
      return _CatalogError(
        message: l10n.catalogLoadError,
        retryLabel: l10n.retry,
        onRetry: () => bloc.add(const BreweryCatalogRetryRequested()),
      );
    }
    if (state.breweries.isEmpty) {
      final hasSearchOrFilters =
          state.query.isNotEmpty || state.activeTypes.isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasSearchOrFilters ? l10n.catalogNoMatches : l10n.noBreweries,
                textAlign: TextAlign.center,
              ),
              if (state.hasMore) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () =>
                      bloc.add(const BreweryCatalogNextPageRequested()),
                  child: Text(l10n.catalogLoadMore),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _loadAheadExtent &&
            state.hasMore &&
            !state.isLoadingMore &&
            state.error == null) {
          bloc.add(const BreweryCatalogNextPageRequested());
        }
        return false;
      },
      child: ListView.builder(
        key: const ValueKey('brewery-catalog-list'),
        itemCount:
            state.breweries.length +
            (state.isLoadingMore || state.error != null || state.hasMore
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == state.breweries.length) {
            if (state.isLoadingMore) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(l10n.loadingMoreBreweries),
                    ],
                  ),
                ),
              );
            }
            if (state.error != null) {
              return Center(
                child: TextButton.icon(
                  onPressed: () =>
                      bloc.add(const BreweryCatalogRetryRequested()),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              );
            }
            return const SizedBox(height: 24);
          }

          final brewery = state.breweries[index];
          final city = brewery.city?.trim();
          final subtitle = [
            brewery.breweryType,
            if (city != null && city.isNotEmpty) city,
          ].join(' · ');
          return ListTile(
            key: ValueKey('brewery-catalog-item-${brewery.id}'),
            title: Text(
              brewery.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onBrewerySelected(brewery),
          );
        },
      ),
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    BreweryCatalogState state,
  ) async {
    final bloc = context.read<BreweryCatalogBloc>();
    final l10n = AppLocalizations.of(context)!;
    var selectedTypes = Set<String>.of(state.activeTypes);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.catalogFilters,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final type in _breweryTypes)
                        CheckboxListTile(
                          value: selectedTypes.contains(type),
                          title: Text(type),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (selected) => setModalState(() {
                            if (selected == true) {
                              selectedTypes.add(type);
                            } else {
                              selectedTypes.remove(type);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        bloc.add(const BreweryCatalogFiltersCleared());
                        Navigator.pop(sheetContext);
                      },
                      child: Text(l10n.catalogClearFilters),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        bloc.add(BreweryCatalogTypesChanged(selectedTypes));
                        Navigator.pop(sheetContext);
                      },
                      child: Text(l10n.catalogApplyFilters),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogSearchField extends StatefulWidget {
  const _CatalogSearchField({
    required this.query,
    required this.hint,
    required this.clearLabel,
    required this.onChanged,
  });

  final String query;
  final String hint;
  final String clearLabel;
  final ValueChanged<String> onChanged;

  @override
  State<_CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends State<_CatalogSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _CatalogSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('brewery-catalog-search'),
    controller: _controller,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: widget.hint,
      prefixIcon: const Icon(Icons.search),
      border: const OutlineInputBorder(),
      isDense: true,
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) => value.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: widget.clearLabel,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                icon: const Icon(Icons.close),
              ),
      ),
    ),
    onChanged: widget.onChanged,
  );
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(retryLabel),
        ),
      ],
    ),
  );
}
