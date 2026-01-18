// lib/app/widgets/camera_live_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:smart_home/app/core/storage/secure_storage.dart';
import 'package:smart_home/app/data/api_client.dart';

class CameraLiveScreen extends StatefulWidget {
  /// Option A) backend live API-гаар playUrl авах (camera.xxx)
  final String? entityId;

  /// Option B) шууд camProxy HLS URL үүсгэх
  final String? edgeId; // edge_nas_01 гэх мэт
  final String? src; // camera_192_168_1_173 гэх мэт

  /// playUrl relative ирвэл үүн дээр resolve хийнэ (Option A үед)
  /// Мөн Option B үед camProxy base болдог.
  final String baseUrl;

  /// Гарчиг
  final String title;

  /// Debug overlay харуулах эсэх
  final bool showDebug;

  const CameraLiveScreen({
    super.key,
    this.entityId,
    this.edgeId,
    this.src,
    this.baseUrl = 'https://api.habea.mn',
    this.title = 'Live',
    this.showDebug = true,
  }) : assert(
          entityId != null || (edgeId != null && src != null),
          'CameraLiveScreen: entityId эсвэл (edgeId, src) заавал өгнө.',
        );

  @override
  State<CameraLiveScreen> createState() => _CameraLiveScreenState();
}

class _CameraLiveScreenState extends State<CameraLiveScreen> {
  late final Player _player;
  late final VideoController _controller;

  bool _opening = true;
  String? _err;
  String? _lastLog;

  bool _buffering = false;
  bool _playing = false;

  StreamSubscription? _errSub;
  StreamSubscription? _logSub;
  StreamSubscription? _bufSub;
  StreamSubscription? _playSub;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _wireStreams();
    _open();
  }

  void _wireStreams() {
    _errSub = _player.stream.error.listen((e) {
      if (!mounted) return;
      setState(() => _err = e.toString());
    });

    _logSub = _player.stream.log.listen((l) {
      if (!mounted) return;
      setState(() => _lastLog = l.toString());
    });

    _bufSub = _player.stream.buffering.listen((b) {
      if (!mounted) return;
      setState(() => _buffering = b);
    });

    _playSub = _player.stream.playing.listen((p) {
      if (!mounted) return;
      setState(() => _playing = p);
    });
  }

  /// Option A: playUrl relative ирвэл absolute болгох
  String _normalizePlayUrl(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return s;
    final u = Uri.tryParse(s);
    if (u == null) return s;
    if (u.hasScheme) return s;
    return Uri.parse(widget.baseUrl).resolve(s).toString();
  }

  /// Option B: camProxy HLS URL
  String _buildCamProxyHlsUrl({
    required String baseUrl,
    required String edgeId,
    required String src,
  }) {
    final base = Uri.parse(baseUrl);
    final path = '/api/cam/$edgeId/api/stream.m3u8';
    final uri = base.replace(
      path: path,
      queryParameters: {
        'src': src,
        // cache bust
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    return uri.toString();
  }

  Future<Map<String, dynamic>> _getLiveWithRetry(String entityId) async {
    Future<Map<String, dynamic>> doReq() async {
      return await ApiClient.I
          .getCameraLive(entityId)
          .timeout(const Duration(seconds: 10));
    }

    try {
      return await doReq();
    } catch (_) {
      return await doReq();
    }
  }

  Future<void> _open() async {
    if (!mounted) return;
    setState(() {
      _opening = true;
      _err = null;
      _lastLog = null;
    });

    try {
      await _player.stop();

      final jwt = await SecureStore.instance.read(SecureKeys.accessToken);

      // ✅ playUrl-г 2 янзаар бэлдэнэ
      String playUrl;

      if (widget.entityId != null) {
        // --- Option A ---
        final live = await _getLiveWithRetry(widget.entityId!);
        final playUrlRaw = (live['playUrl'] ?? live['url'] ?? '').toString();
        playUrl = _normalizePlayUrl(playUrlRaw);

        if (playUrl.isEmpty) {
          throw Exception('playUrl хоосон байна. live payload: $live');
        }
      } else {
        // --- Option B ---
        playUrl = _buildCamProxyHlsUrl(
          baseUrl: widget.baseUrl,
          edgeId: widget.edgeId!,
          src: widget.src!,
        );
      }

      debugPrint('[CAM] playUrl=$playUrl');

      final headers = <String, String>{
        'User-Agent': 'SmartHomeApp/1.0',
        if ((jwt ?? '').isNotEmpty) 'Authorization': 'Bearer $jwt',
      };

      await _player.open(
        Media(playUrl, httpHeaders: headers),
        play: true,
      );

      // жижиг post-check (buffering гацвал error hint харуулна)
      unawaited(_postOpenCheck());
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _opening = false);
    }
  }

  Future<void> _postOpenCheck() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (!_playing && _buffering && _err == null) {
      setState(() {
        _err =
            'Buffering дээр гацаж байна.\n'
            'HLS playlist/segment дээр Authorization header дамжихгүй эсвэл proxy талд асуудалтай байж магадгүй.\n'
            '→ CamProxy-г playlist+segment proxy болгох, эсвэл сегментүүд auth-гүй (signed URL) болгох хэрэг гарч болно.';
      });
    }
  }

  @override
  void dispose() {
    _errSub?.cancel();
    _logSub?.cancel();
    _bufSub?.cancel();
    _playSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _open,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(
                controller: _controller,
                fit: BoxFit.cover,
              ),
            ),
          ),

          if (_opening) const Center(child: CircularProgressIndicator()),

          if (widget.showDebug)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: _DebugBox(
                lines: [
                  'entityId: ${widget.entityId ?? "-"}',
                  'edgeId: ${widget.edgeId ?? "-"}',
                  'src: ${widget.src ?? "-"}',
                  'opening: $_opening',
                  'playing: $_playing  buffering: $_buffering',
                  if (_lastLog != null) 'log: $_lastLog',
                ],
              ),
            ),

          if (_err != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                color: Colors.black.withOpacity(0.82),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playback error',
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_err!, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _open,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _err = null),
                            icon: const Icon(Icons.close),
                            label: const Text('Hide'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DebugBox extends StatelessWidget {
  final List<String> lines;
  const _DebugBox({required this.lines});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.25,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map((e) => Text(
                      e,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
