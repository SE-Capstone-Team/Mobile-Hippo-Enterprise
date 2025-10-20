import 'package:flutter/material.dart';
import '../Firebase/Firebase_service.dart';

/// Widget to display cache statistics for debugging purposes
class CacheStatsWidget extends StatefulWidget {
  const CacheStatsWidget({Key? key}) : super(key: key);

  @override
  State<CacheStatsWidget> createState() => _CacheStatsWidgetState();
}

class _CacheStatsWidgetState extends State<CacheStatsWidget> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _cacheStats;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  void _loadCacheStats() {
    setState(() {
      _cacheStats = _authService.getCacheStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cache Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadCacheStats,
                  tooltip: 'Refresh stats',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_cacheStats != null) ...[
              _buildStatRow('Cached Items', '${_cacheStats!['totalItems']}'),
              _buildStatRow('Expired Items', '${_cacheStats!['expiredItems']}'),
              _buildStatRow('Max Cache Size', '${_cacheStats!['maxSize']}'),
              _buildStatRow('Cache Expiry', '${_cacheStats!['defaultExpiryMinutes']} min'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _authService.clearItemCache();
                        _loadCacheStats();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear Cache'),
                    ),
                  ),
                ],
              ),
            ] else
              const Text('Loading cache statistics...'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
