import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'macbearnet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'macbearnet'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WebAppPage(
                      url: 'https://macbearnet.co.kr',
                    ),
                  ),
                );
              },
              child: const Text('메인 버튼'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WebAppPage extends StatefulWidget {
  const WebAppPage({super.key, required this.url});

  final String url;

  @override
  State<WebAppPage> createState() => _WebAppPageState();
}

class _WebAppPageState extends State<WebAppPage> with WidgetsBindingObserver {
  static const _chromeLikeUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';

  late final WebViewController _controller;
  String? _webError;
  bool _isLoading = true;
  /// [reload]는 첫 로드와 겹치면 iOS에서 크래시가 날 수 있어, 백그라운드에 갔다온 뒤에만 호출한다.
  bool _sawBackground = false;

  WebViewController _createController() {
    final WebViewController c;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      c = WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams
            .fromPlatformWebViewControllerCreationParams(
          const PlatformWebViewControllerCreationParams(),
        ),
      );
    } else {
      c = WebViewController();
    }
    c
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final scheme = uri?.scheme.toLowerCase();
            if (scheme == 'http' || scheme == 'https') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            setState(() {
              _webError = null;
              _isLoading = true;
            });
          },
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
          onHttpError: (HttpResponseError error) {
            final code = error.response?.statusCode;
            setState(() {
              _webError = 'HTTP 오류${code != null ? ' ($code)' : ''}';
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _webError =
                  '웹페이지 로드 실패 (code: ${error.errorCode})\n${error.description}';
              _isLoading = false;
            });
          },
          onSslAuthError: (SslAuthError error) {
            setState(() {
              _webError = 'SSL 인증서 경고 — 연결을 계속 시도 중입니다';
            });
            error.proceed();
          },
        ),
      );
    return c;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _createController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWithPlatformUserAgent();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _sawBackground = true;
      return;
    }
    if (state != AppLifecycleState.resumed || !_sawBackground) {
      return;
    }
    _sawBackground = false;
    if (!Platform.isIOS || !mounted) return;
    // 첫 resume 직후와 loadRequest가 겹치지 않게 짧게 늦춘 뒤 갱신
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 300), () async {
        if (!mounted) return;
        try {
          await _controller.reload();
        } catch (_) {
          // 이미 WebView가 정리됐거나 로딩 중이면 무시
        }
      }),
    );
  }

  Future<void> _applyAndroidWebViewTweaks() async {
    if (WebViewPlatform.instance is! AndroidWebViewPlatform) return;
    final AndroidWebViewController android =
        _controller.platform as AndroidWebViewController;
    await android.setMixedContentMode(MixedContentMode.alwaysAllow);
    await android.setUseWideViewPort(true);
  }

  /// iOS는 데스크톱 Chrome UA로 두면 사이트가 잘못 응답·흰 화면만 주는 경우가 있어, 기본(WK) UA를 쓴다.
  Future<void> _loadWithPlatformUserAgent() async {
    await _applyAndroidWebViewTweaks();
    if (Platform.isAndroid) {
      await _controller.setUserAgent(_chromeLikeUserAgent);
    }
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('웹앱')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && _webError == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('불러오는 중…'),
                ],
              ),
            ),
          if (_webError != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                color: Colors.black87,
                child: Text(
                  _webError!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
