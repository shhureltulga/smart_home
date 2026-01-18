import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_home/app/core/storage/secure_storage.dart';
import 'package:smart_home/app/data/api_client.dart';
import 'package:smart_home/app/widgets/camera_live_screen.dart';

class CameraDeviceCard extends StatefulWidget {
  final String title;     // UI нэр
  final String entityId;  // camera.xxx
  final String edgeBaseUrl; // (optional) одоохондоо хэрэглэхгүй байж болно

  const CameraDeviceCard({
    super.key,
    required this.title,
    required this.entityId,
    this.edgeBaseUrl = 'https://api.habea.mn',
  });

  @override
  State<CameraDeviceCard> createState() => _CameraDeviceCardState();
}

class _CameraDeviceCardState extends State<CameraDeviceCard> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    // main backend: /api/camera/:entityId/live  (чи ийм API хийсэн гэж үзэж байна)
    final live = await ApiClient.I.getCameraLive(widget.entityId);
    return live;
  }

  Future<String?> _getToken() async {
    return SecureStore.instance.read(SecureKeys.accessToken);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  void _openLive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraLiveScreen(entityId: widget.entityId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openLive,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'Camera error: ${snap.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            final live = snap.data!;
            final snapshotUrl = (live['snapshotUrl'] ?? '').toString();

            return FutureBuilder<String?>(
              future: _getToken(),
              builder: (ctx, tokSnap) {
                final token = tokSnap.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (snapshotUrl.isNotEmpty)
                            Image.network(
                              // ✅ cache bust
                              snapshotUrl + (snapshotUrl.contains('?') ? '&' : '?') + 't=${DateTime.now().millisecondsSinceEpoch}',
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              headers: {
                                if ((token ?? '').isNotEmpty)
                                  'Authorization': 'Bearer $token',
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black26,
                                child: const Center(child: Icon(Icons.videocam_off)),
                              ),
                            )
                          else
                            Container(
                              color: Colors.black26,
                              child: const Center(child: Icon(Icons.videocam)),
                            ),

                          Container(color: Colors.black.withOpacity(0.15)),
                          const Center(
                            child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                          ),

                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black.withOpacity(0.35),
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                onPressed: _refresh,
                                tooltip: 'Refresh snapshot',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
