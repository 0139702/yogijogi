import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'prime_floor.dart';

class Campus3dScreen extends StatefulWidget {
  const Campus3dScreen({
    super.key,
    required this.onPlace,
    required this.filter,
    this.indoor = false,
    this.active = true,
    this.route = const [],
    this.step,
  });

  final ValueChanged<String> onPlace;
  final String filter;
  final bool indoor;
  final bool active;
  final List<Offset> route;
  final int? step;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Campus3dScreenState createState() => Campus3dScreenState();
}

class Campus3dScreenState extends State<Campus3dScreen> {
  static const _viewer = 'assets/3d/campus-viewer.html';
  static const _models = {
    'campus': 'assets/3d/sungshin-campus-obj.zip',
    'mascot': 'assets/3d/suryongi-v4.stl.gz',
  };

  WebViewController? _controller;
  bool _loadingModels = false;
  bool _ready = false;
  bool _failed = false;

  Timer? _loadTimeout;
  final _startup = Stopwatch();

  @override
  void initState() {
    super.initState();
    if (Campus3dScreen.isSupported) {
      _startup.start();
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
              _syncScene();
              _startup.stop();
              if (!kReleaseMode) {
                debugPrint(
                  '[YogiPerf] viewer_to_first_frame_ms=${_startup.elapsedMilliseconds}',
                );
              }
            case 'error':
              _showError();
            default:
              if (!kReleaseMode && message.message.startsWith('perf:')) {
                debugPrint('[YogiPerf] ${message.message.substring(5)}');
              } else if (widget.active &&
                  message.message.startsWith('place:')) {
                widget.onPlace(message.message.substring(6));
              }
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
        const chunkSize = 192 * 1024;
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
      final rooms = [
        for (final place in primeFloorPlaces)
          {
            'id': place.name,
            'label': place.mapLabel,
            'rect': [
              place.bounds!.left,
              place.bounds!.top,
              place.bounds!.width,
              place.bounds!.height,
            ],
          },
      ];
      final hall = [
        primeCorridor.left,
        primeCorridor.top,
        primeCorridor.width,
        primeCorridor.height,
      ];
      if (mounted) {
        await controller.runJavaScript(
          'window.yogiCampus.start(${jsonEncode(rooms)}, ${jsonEncode(hall)}, ${widget.indoor}, ${jsonEncode(widget.filter)}, ${widget.active}, ${!kReleaseMode});',
        );
      }
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
  void didUpdateWidget(covariant Campus3dScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.indoor != widget.indoor ||
        oldWidget.active != widget.active ||
        oldWidget.step != widget.step ||
        !listEquals(oldWidget.route, widget.route)) {
      _syncScene();
    }
  }

  String? _pendingFocus;

  void focusPlace(String id) => _focus(id);
  void focusMascot() => _focus('mascot');

  void _focus(String id) {
    if (_ready) {
      _command('focus(${jsonEncode(id)})');
    } else {
      _pendingFocus = id;
    }
  }

  void _syncScene() {
    if (_ready) {
      _command(
        'show(${widget.indoor}, ${jsonEncode(widget.filter)}, ${widget.active})',
      );
      final points = [
        for (final point in widget.route) [point.dx, point.dy],
      ];
      _command('route(${jsonEncode(points)}, ${widget.step})');
      final pending = _pendingFocus;
      if (pending != null) {
        _pendingFocus = null;
        _focus(pending);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(child: Text('3D 지도를 불러오지 못했습니다.'));
    }
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller != null) WebViewWidget(controller: controller),
        if (!_ready)
          const ColoredBox(
            color: Color(0xffeaf0ea),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
