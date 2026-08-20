import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:great_memories_mobile/domain/models/asset/base_asset.model.dart';
import 'package:great_memories_mobile/extensions/translate_extensions.dart';
import 'package:great_memories_mobile/models/search/search_filter.model.dart';
import 'package:great_memories_mobile/presentation/pages/search/paginated_search.provider.dart';
import 'package:great_memories_mobile/presentation/widgets/action_buttons/base_action_button.widget.dart';
import 'package:great_memories_mobile/providers/asset_viewer/asset_viewer.provider.dart';
import 'package:great_memories_mobile/routing/router.dart';

class SimilarPhotosActionButton extends ConsumerWidget {
  final String assetId;
  final bool iconOnly;
  final bool menuItem;

  const SimilarPhotosActionButton({super.key, required this.assetId, this.iconOnly = false, this.menuItem = false});

  void _onTap(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) {
      return;
    }

    ref.invalidate(assetViewerProvider);
    ref.invalidate(paginatedSearchProvider);

    ref.read(searchPreFilterProvider.notifier)
      ..clear()
      ..setFilter(
        SearchFilter(
          assetId: assetId,
          people: {},
          location: SearchLocationFilter(),
          camera: SearchCameraFilter(),
          date: SearchDateFilter(),
          display: SearchDisplayFilters(isNotInAlbum: false, isArchive: false, isFavorite: false),
          rating: SearchRatingFilter(),
          mediaType: AssetType.other,
        ),
      );

    unawaited(context.navigateTo(const DriftSearchRoute()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseActionButton(
      iconData: Icons.compare,
      label: "view_similar_photos".t(context: context),
      iconOnly: iconOnly,
      menuItem: menuItem,
      onPressed: () => _onTap(context, ref),
      maxWidth: 100,
    );
  }
}
