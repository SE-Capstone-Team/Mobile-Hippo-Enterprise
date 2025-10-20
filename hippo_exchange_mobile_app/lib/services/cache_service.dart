import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Cached item wrapper with metadata
class CachedItem {
  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final Duration expiry;

  CachedItem({
    required this.data,
    required this.cachedAt,
    this.expiry = const Duration(minutes: 30),
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > expiry;
}

/// A singleton cache service for storing item data and managing cache lifecycle
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // In-memory cache for item data
  final Map<String, CachedItem> _itemCache = {};
  
  // Cache configuration
  static const Duration defaultCacheExpiry = Duration(minutes: 30);
  static const int maxCacheSize = 1000;

  /// Get item from cache
  Map<String, dynamic>? getItem(String itemId) {
    final cachedItem = _itemCache[itemId];
    if (cachedItem == null || cachedItem.isExpired) {
      if (cachedItem != null && cachedItem.isExpired) {
        _itemCache.remove(itemId);
      }
      return null;
    }
    return cachedItem.data;
  }

  /// Store item in cache
  void cacheItem(String itemId, Map<String, dynamic> itemData, {Duration? expiry}) {
    // Ensure cache doesn't grow too large
    if (_itemCache.length >= maxCacheSize) {
      _evictOldestItems();
    }

    _itemCache[itemId] = CachedItem(
      data: Map<String, dynamic>.from(itemData),
      cachedAt: DateTime.now(),
      expiry: expiry ?? defaultCacheExpiry,
    );
  }

  /// Update existing cached item
  void updateCachedItem(String itemId, Map<String, dynamic> updates) {
    final cachedItem = _itemCache[itemId];
    if (cachedItem != null && !cachedItem.isExpired) {
      final updatedData = Map<String, dynamic>.from(cachedItem.data);
      updatedData.addAll(updates);
      
      _itemCache[itemId] = CachedItem(
        data: updatedData,
        cachedAt: DateTime.now(), // Reset cache time on update
        expiry: cachedItem.expiry,
      );
    }
  }

  /// Remove specific item from cache
  void invalidateItem(String itemId) {
    _itemCache.remove(itemId);
  }

  /// Clear all cached items
  void clearAllItems() {
    _itemCache.clear();
  }

  /// Clear expired items
  void clearExpiredItems() {
    final expiredKeys = _itemCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _itemCache.remove(key);
    }
  }

  /// Evict oldest items when cache is full
  void _evictOldestItems() {
    // Remove 20% of cache when full
    final itemsToRemove = (maxCacheSize * 0.2).round();
    final sortedItems = _itemCache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    
    for (int i = 0; i < itemsToRemove && i < sortedItems.length; i++) {
      _itemCache.remove(sortedItems[i].key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalItems': _itemCache.length,
      'expiredItems': _itemCache.values.where((item) => item.isExpired).length,
      'maxSize': maxCacheSize,
      'defaultExpiryMinutes': defaultCacheExpiry.inMinutes,
    };
  }

  /// Cache multiple items (useful for list views)
  void cacheItems(Map<String, Map<String, dynamic>> items, {Duration? expiry}) {
    items.forEach((itemId, itemData) {
      cacheItem(itemId, itemData, expiry: expiry);
    });
  }

  /// Preload items from QuerySnapshot
  void cacheItemsFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot, {Duration? expiry}) {
    for (final doc in snapshot.docs) {
      cacheItem(doc.id, doc.data(), expiry: expiry);
    }
  }

  /// Check if item exists in cache and is not expired
  bool hasValidCachedItem(String itemId) {
    final cachedItem = _itemCache[itemId];
    return cachedItem != null && !cachedItem.isExpired;
  }

  /// Bulk invalidate items by IDs
  void invalidateItems(List<String> itemIds) {
    for (final itemId in itemIds) {
      _itemCache.remove(itemId);
    }
  }

  /// Get cached items count
  int get cachedItemsCount => _itemCache.length;

  /// Get all cached item IDs
  List<String> get cachedItemIds => _itemCache.keys.toList();
}
