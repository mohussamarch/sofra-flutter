import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../domain/places.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';

/// Asks for a city or district from the bundled list of the current country,
/// so the saved area is a map label and its prices pool with the map's.
Future<Place?> showPlacePicker(BuildContext context) {
  final places = SofraScope.controllerOf(context).places();
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Sofra.paper,
    builder: (_) => _PlaceSheet(places: places),
  );
}

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({required this.places});
  final Future<Places> places;
  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  final search = TextEditingController();
  Places? places;
  List<Place> hits = const [];

  @override
  void initState() {
    super.initState();
    widget.places.then((p) {
      if (!mounted) return;
      setState(() {
        places = p;
        hits = p.search(search.text);
      });
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: 20,
      end: 20,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('place-picker-search'),
            controller: search,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n.priceSearchArea,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (v) =>
                setState(() => hits = places?.search(v) ?? const []),
            onSubmitted: (_) {
              if (hits.isNotEmpty) Navigator.pop(context, hits.first);
            },
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in hits)
                  ListTile(
                    key: ValueKey('place-pick-${p.label}'),
                    leading: Icon(
                      p.isCity
                          ? Icons.location_city_rounded
                          : Icons.place_rounded,
                      color: Sofra.accent,
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: p.city == null || p.city == p.name
                        ? null
                        : Text(p.city!),
                    onTap: () => Navigator.pop(context, p),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
