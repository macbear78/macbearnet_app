import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
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

class _WebAppPageState extends State<WebAppPage> {
  static const _chromeLikeUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';

  late final WebViewController _controller;
  String? _webError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
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
            });
          },
          onHttpError: (HttpResponseError error) {
            final code = error.response?.statusCode;
            setState(() {
              _webError = 'HTTP 오류${code != null ? ' ($code)' : ''}';
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _webError =
                  '웹페이지 로드 실패 (code: ${error.errorCode})\n${error.description}';
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
    _loadWithDesktopLikeAgent();
  }

  Future<void> _applyAndroidWebViewTweaks() async {
    if (WebViewPlatform.instance is! AndroidWebViewPlatform) return;
    final AndroidWebViewController android =
        _controller.platform as AndroidWebViewController;
    await android.setMixedContentMode(MixedContentMode.alwaysAllow);
    await android.setUseWideViewPort(true);
  }

  Future<void> _loadWithDesktopLikeAgent() async {
    await _applyAndroidWebViewTweaks();
    await _controller.setUserAgent(_chromeLikeUserAgent);
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('웹앱')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
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
