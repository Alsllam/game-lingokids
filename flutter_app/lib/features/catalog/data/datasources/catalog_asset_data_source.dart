import 'dart:convert';

import 'package:flutter/services.dart';

/// Reads the bundled content file.
///
/// To download content on demand later, add a second data source with the
/// same method and let the repository choose between them.
class CatalogAssetDataSource {
  const CatalogAssetDataSource({
    required AssetBundle bundle,
    this.path = 'assets/content/catalog.json',
  }) : _bundle = bundle;

  final AssetBundle _bundle;
  final String path;

  Future<Object?> readCatalogJson() async {
    final raw = await _bundle.loadString(path);
    return jsonDecode(raw);
  }
}
