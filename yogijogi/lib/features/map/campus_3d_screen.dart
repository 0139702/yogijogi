import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Campus3dScreen extends StatefulWidget {
  const Campus3dScreen({super.key});

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<Campus3dScreen> createState() => _Campus3dScreenState();
}

class _Campus3dScreenState extends State<Campus3dScreen> {
  static const _viewer = 'assets/3d/campus-viewer.html';
  static const _models = {
    'campus': 'assets/3d/sungshin-campus-obj.zip',
    'mascot': 'assets/3d/suryongi_mascot_3d_bundle.zip',
  };

  WebViewController? _controller;
  bool _loadingModels = false;
  bool _ready = false;
  bool _failed = false;
  bool _walking = false;
  bool _following = false;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    if (Campus3dScreen.isSupported) {
      _loadTimeout = Timer(const Duration(seconds: 45), _showError);
      _open();
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      final controller = WebViewController();
      setState(() => _controller = controller);
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = Uri.tryParse(request.url);
            return url?.scheme == 'file' && url!.path.endsWith('/$_viewer')
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != false) _showError();
          },
        ),
      );
      await controller.addJavaScriptChannel(
        'CampusViewer',
        onMessageReceived: (message) async {
          if (!mounted) return;
          switch (message.message) {
            case 'loader-ready':
              await _loadModels(controller);
            case 'ready':
              _loadTimeout?.cancel();
              setState(() => _ready = true);
            case 'error':
              _showError();
          }
        },
      );
      if (mounted) await controller.loadFlutterAsset(_viewer);
    } on Exception {
      _showError();
    }
  }

  Future<void> _loadModels(WebViewController controller) async {
    if (_loadingModels) return;
    _loadingModels = true;
    try {
      for (final entry in _models.entries) {
        final bytes = await rootBundle.load(entry.value);
        final encoded = base64Encode(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        const chunkSize = 64 * 1024;
        for (var i = 0; i < encoded.length; i += chunkSize) {
          if (!mounted) return;
          final chunk = encoded.substring(
            i,
            min(i + chunkSize, encoded.length),
          );
          await controller.runJavaScript(
            'window.yogiCampus.append(${jsonEncode(entry.key)}, ${jsonEncode(chunk)});',
          );
        }
      }
      if (mounted) await controller.runJavaScript('window.yogiCampus.start();');
    } on Exception {
      _showError();
    }
  }

  void _showError() {
    _loadTimeout?.cancel();
    if (mounted) setState(() => _failed = true);
  }

  Future<void> _command(String command) async {
    try {
      await _controller?.runJavaScript('window.yogiCampus.$command;');
    } on Exception {
      _showError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('수정캠퍼스 3D 지도')),
      body: switch ((Campus3dScreen.isSupported, _failed, controller)) {
        (false, _, _) => const Center(
          child: Text('3D 지도는 Android와 iOS에서 볼 수 있습니다.'),
        ),
        (_, true, _) => const Center(
          child: Text('3D 지도를 열 수 없습니다. 뒤로 가면 층 안내도를 볼 수 있어요.'),
        ),
        (_, _, null) => const Center(child: CircularProgressIndicator()),
        (_, _, final webView?) => Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: webView),
            if (!_ready)
              const ColoredBox(
                color: Color(0xffeaf0ea),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('캠퍼스 모델 · 수룡이 이동 데모'),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() => _walking = !_walking);
                                  _command('walk($_walking)');
                                },
                                child: Text(_walking ? '이동 멈추기' : '수룡이 이동'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() => _following = !_following);
                                  _command('follow($_following)');
                                },
                                child: Text(_following ? '전체 보기' : '수룡이 따라가기'),
                              ),
                              IconButton(
                                tooltip: '시점 초기화',
                                onPressed: () {
                                  setState(() => _following = false);
                                  _command('reset()');
                                },
                                icon: const Icon(Icons.center_focus_strong),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      },
    );
  }
}
