import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({super.key, required this.title, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showTimeoutHelp = false;
  Timer? _timeoutTimer;

  // User-Agent حقيقي يتنكر كأنه Chrome على Android
  // هذا يحل 90% من مشاكل المواقع التي تحظر WebView
  static const String _realUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(_realUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
            _startTimeout();
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            _cancelTimeout();
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
            _cancelTimeout();
          },
          onNavigationRequest: (request) {
            // منع فتح روابط المتاجر والإعلانات
            if (request.url.startsWith('intent://') ||
                request.url.contains('play.google.com') ||
                request.url.contains('apps.apple.com') ||
                request.url.contains('about:blank')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _startTimeout() {
    _cancelTimeout();
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        setState(() => _showTimeoutHelp = true);
      }
    });
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (mounted && _showTimeoutHelp) {
      setState(() => _showTimeoutHelp = false);
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'فتح في المتصفح',
              onPressed: _openInExternalBrowser,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'إعادة تحميل',
              onPressed: () {
                _controller.reload();
                setState(() => _isLoading = true);
                _startTimeout();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.transparent,
                ),
              ),
            if (_showTimeoutHelp)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: AppColors.warning, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'المصدر يبدو بطيئاً أو محظوراً',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'يمكنك فتح الرابط في المتصفح الخارجي، أو تجربة مصدر آخر من القائمة.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _openInExternalBrowser,
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('فتح في المتصفح الخارجي'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.list_rounded),
                            label: const Text('العودة لقائمة المصادر'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
