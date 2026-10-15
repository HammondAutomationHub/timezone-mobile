import 'package:flutter/material.dart';

import '../data/place_catalog.dart';
import '../logic/clock.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';

class AddPlacePage extends StatefulWidget {
  const AddPlacePage({
    required this.catalog,
    required this.savedIds,
    required this.now,
    required this.onAdd,
    super.key,
  });

  final PlaceCatalog catalog;
  final Set<String> savedIds;
  final DateTime now;
  final ValueChanged<Place> onAdd;

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final _controller = TextEditingController();
  late final Set<String> _savedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _savedIds = {...widget.savedIds};
  }

  @override
  void didUpdateWidget(AddPlacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _savedIds.addAll(widget.savedIds);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(Place place) {
    if (_savedIds.contains(place.id)) return;
    setState(() => _savedIds.add(place.id));
    widget.onAdd(place);
  }

  void _submitFirst(List<Place> results) {
    for (final place in results) {
      if (_savedIds.contains(place.id)) continue;
      _add(place);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final results = query.isEmpty
        ? const <Place>[]
        : widget.catalog.search(query);

    return Scaffold(
      appBar: AppBar(title: const Text('Add a place')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search cities or countries',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (_) => _submitFirst(results),
                ),
              ),
              Expanded(
                child: query.isEmpty
                    ? _BrowseList(
                        catalog: widget.catalog,
                        now: widget.now,
                        savedIds: _savedIds,
                        onAdd: _add,
                      )
                    : results.isEmpty
                    ? const Center(
                        child: Text(
                          'No places match that search.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : _PlaceList(
                        places: results,
                        now: widget.now,
                        savedIds: _savedIds,
                        onAdd: _add,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseList extends StatelessWidget {
  const _BrowseList({
    required this.catalog,
    required this.now,
    required this.savedIds,
    required this.onAdd,
  });

  final PlaceCatalog catalog;
  final DateTime now;
  final Set<String> savedIds;
  final ValueChanged<Place> onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _SectionLabel('Suggested'),
        _PlaceList(
          places: catalog.starters,
          now: now,
          savedIds: savedIds,
          onAdd: onAdd,
          shrinkWrap: true,
        ),
        const _SectionLabel('Cities'),
        _PlaceList(
          places: catalog.popular,
          now: now,
          savedIds: savedIds,
          onAdd: onAdd,
          shrinkWrap: true,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({
    required this.places,
    required this.now,
    required this.savedIds,
    required this.onAdd,
    this.shrinkWrap = false,
  });

  final List<Place> places;
  final DateTime now;
  final Set<String> savedIds;
  final ValueChanged<Place> onAdd;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        final added = savedIds.contains(place.id);
        final clock = ZoneClock.resolve(place.ianaId, now);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            place.label,
            style: TextStyle(
              color: added ? AppColors.faint : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${place.subtitle} · ${formatClock(clock.local)} · ${formatRelativeOffset(clock.relative)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted),
          ),
          trailing: added
              ? const Text(
                  'Added',
                  style: TextStyle(color: AppColors.faint, fontSize: 13),
                )
              : const Icon(Icons.add, color: AppColors.ink),
          onTap: added ? null : () => onAdd(place),
        );
      },
    );
  }
}
