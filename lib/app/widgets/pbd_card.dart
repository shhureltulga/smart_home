import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PbdCardController {
  void Function(List<Map<String, dynamic>>)? setDevices;
  void Function(String deviceId, String action, dynamic value)? sendCmdToJs;
}

class PbdCard extends StatefulWidget {
  final String baseUrl;
  final String siteId;
  final String jwt;
  final double height;
  final String? floorId; 
  final List<Map<String, dynamic>> devices;

  final PbdCardController? controller;

  const PbdCard({
    super.key,
    required this.baseUrl,
    required this.siteId,
    required this.jwt,
    this.floorId,     
    this.height = 300,
    this.devices = const [],
    this.controller,
  });

  @override
  State<PbdCard> createState() => _PbdCardState();
}

class _PbdCardState extends State<PbdCard> with WidgetsBindingObserver {
  late final WebViewController _ctrl;

  bool _fs = false;                       // fullscreen state
  OverlayEntry? _fsEntry;                 // overlay хадгалах

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('APPLOG',
          onMessageReceived: (m) => debugPrint('[PBD] ${m.message}'))
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            final payload = jsonEncode({
              'baseUrl': widget.baseUrl,
              'siteId': widget.siteId,
              'floorId': widget.floorId ?? '',
              'jwt': widget.jwt,
            });
            try {
              await _ctrl.runJavaScript(
                'window.INIT=$payload; window.start && window.start();',
              );
            } catch (e) {
              debugPrint('WV inject error: $e');
            }
          },
          onWebResourceError: (e) =>
              debugPrint('WV error: ${e.errorCode} ${e.description}'),
        ),
      )
      ..loadFlutterAsset('assets/pbd_view_v2.html');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeFsOverlay();
    super.dispose();
  }

  // Keyboard, эргэлт гэх мэт хэмжээс өөрчлөгдөх үед 3D-ээ fit хийнэ
  @override
  void didChangeMetrics() {
    _notifyJsResize();
  }

  Future<void> _notifyJsResize() async {
    try {
      await _ctrl.runJavaScript(
        'window.dispatchEvent(new Event("resize"));'
        'if (typeof fitToContent==="function") fitToContent();',
      );
    } catch (_) {}
  }

  void _enterFs() {
    if (_fsEntry != null) return;

    _fsEntry = OverlayEntry(
      builder: (context) => Material(
        color: const Color(0xFF0B1117),
        child: Stack(
          children: [
            // FULLSCREEN WebView — ижил controller
            Positioned.fill(child: WebViewWidget(controller: _ctrl)),

            // Exit FS
            Positioned(
              top: 12,
              right: 12,
              child: _CircleIconButton(
                icon: Icons.fullscreen_exit_rounded,
                onTap: _toggleFs,
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_fsEntry!);
    setState(() => _fs = true);

    // дараагийн frame дээр resize/fit
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyJsResize());
  }

  void _removeFsOverlay() {
    _fsEntry?.remove();
    _fsEntry = null;
  }

  void _exitFs() {
    _removeFsOverlay();
    setState(() => _fs = false);

    // карт руу буцаан орох үед хэмжээ өөрчлөгдөв → fit
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyJsResize());
  }

  void _toggleFs() {
    if (_fs) {
      _exitFs();
    } else {
      _enterFs();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Жирийн карт — fullscreen үед WebView-г картанд үзүүлэхгүй (нэг л газар амьдрах ёстой)
    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: const Color(0xFF0F1115),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: widget.height,
            child: !_fs
                ? WebViewWidget(controller: _ctrl)
                : const SizedBox.shrink(), // FS үед overlay дээр байдаг
          ),
        ),

        // FS руу оруулах товч — зөвхөн жирийн горимд
        if (!_fs)
          Positioned(
            right: 12,
            bottom: 12,
            child: _CircleIconButton(
              icon: Icons.fullscreen_rounded,
              onTap: _toggleFs,
            ),
          ),
      ],
    );
  }
  Future<void> _injectInit() async {
    final payload = jsonEncode({
      'baseUrl': widget.baseUrl,
      'siteId' : widget.siteId,
      'floorId': widget.floorId ?? '',
      'jwt'    : widget.jwt,
    });
    await _ctrl.runJavaScript(
      'window.INIT=$payload; window.start && window.start();'
    );
  }

  @override
  void didUpdateWidget(covariant PbdCard old) {
    super.didUpdateWidget(old);
    if (old.floorId != widget.floorId) {
      // HTML талд бэлдсэн switch функцыг эхлээд оролдоно,
      // байхгүй бол бүрэн reload (санах ой бага).
      _ctrl.runJavaScript(
        'window.switchFloor && window.switchFloor(${jsonEncode(widget.floorId ?? "")});'
      ).catchError((_) async {
        await _injectInit();
        await _ctrl.reload();
      });
    }
  }


}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF17212B),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: const Color(0xFFB8D9E9)),
        ),
      ),
    );
  }
}
