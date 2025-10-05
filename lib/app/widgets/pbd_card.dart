import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PbdCard extends StatefulWidget {
  final String baseUrl; // жишээ: https://api.habea.mn
  final String siteId;  // тухайн site UUID
  final String jwt;     // хэрэглэгчийн JWT
  final double height;

  const PbdCard({
    super.key,
    required this.baseUrl,
    required this.siteId,
    required this.jwt,
    this.height = 260,
  });

  @override
  State<PbdCard> createState() => _PbdCardState();
}

class _PbdCardState extends State<PbdCard> {
  late final WebViewController _ctrl;

  @override
  void initState() {
    super.initState();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'APPLOG',
        onMessageReceived: (m) => debugPrint('[PBD] ${m.message}'),
      )
      ..setBackgroundColor(const Color(0x00000000))
      ..loadFlutterAsset('assets/pbd_view.html')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            debugPrint('WV finished: $url');
            final payload = jsonEncode({
              'baseUrl': widget.baseUrl,
              'siteId' : widget.siteId,
              'jwt'    : widget.jwt,
            });
            await _ctrl
                .runJavaScript('window.INIT=$payload; window.start && window.start();')
                .catchError((e) => debugPrint('WV inject error: $e'));
          },
          onWebResourceError: (err) {
            debugPrint('WV resource error: ${err.errorCode} ${err.description}');
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F1115),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: WebViewWidget(controller: _ctrl),
        ),
      ),
    );
  }
}
