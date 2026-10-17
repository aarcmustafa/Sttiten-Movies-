import 'package:flutter/services.dart';
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
  String _initialHost = '';

  // User-Agent حقيقي (يتنكر كأنه Chrome على Android)
  static const String _realUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  // قائمة النطاقات المحظورة (الإعلانات وصفحات البحث)
  static const List<String> _blockedHosts = [
    'google.com',
    'google.co',
    'bing.com',
    'yahoo.com',
    'duckduckgo.com',
    'yandex.com',
    'baidu.com',
    'play.google.com',
    'apps.apple.com',
    'instagram.com',
    'facebook.com',
    'twitter.com',
    'tiktok.com',
    'doubleclick.net',
    'googlesyndication.com',
    'googletagmanager.com',
    'google-analytics.com',
    'propellerads.com',
    'popads.net',
    'adsterra.com',
    'onclickads.net',
  ];

  bool _isBlocked(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      if (host.isEmpty) return false;
      
      for (final blocked in _blockedHosts) {
        if (host == blocked || host.endsWith('.$blocked')) return true;
      }
      
      // منع الروابط التي تحتوي على كلمات بحث
      final path = uri.path.toLowerCase();
      if (path.contains('/search') && !_initialHost.contains(uri.host)) return true;
      
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    // السماح بالتدوير الحر
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initialHost = Uri.parse(widget.url).host;
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
            _injectAntiRedirectScript();
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
            _cancelTimeout();
          },
          onNavigationRequest: (request) {
            // منع أي رابط محظور
            if (_isBlocked(request.url)) {
              debugPrint('🚫 Blocked navigation: ${request.url}');
              return NavigationDecision.prevent;
            }
            // منع الروابط التي تفتح متجر التطبيقات
            if (request.url.startsWith('intent://') ||
                request.url.startsWith('market://') ||
                request.url.contains('about:blank')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // حقن جافاسكريبت لمنع الإعلانات والنوافذ المنبثقة
  Future<void> _injectAntiRedirectScript() async {
    try {
      await _controller.runJavaScript('''
        (function() {
          // 1. منع window.open والنوافذ المنبثقة
          window.open = function() { return null; };
          window.alert = function() { return null; };
          window.confirm = function() { return false; };
          
          // 2. اعتراض أي نقرة تذهب إلى موقع خارجي
          document.addEventListener('click', function(e) {
            var target = e.target.closest('a');
            if (target && target.href) {
              var href = target.href.toLowerCase();
              if (href.includes('google') || href.includes('bing') || 
                  href.includes('yahoo') || href.includes('play.google')) {
                e.preventDefault();
                e.stopPropagation();
                return false;
              }
            }
          }, true);
          
          // 3. إخفاء الإعلانات باستمرار
          setInterval(function() {
            var adSelectors = [
              'iframe[src*="ad"]', 'iframe[src*="banner"]',
              'div[class*="ad-"]', 'div[id*="ad-"]', 
              '.adsbygoogle', 'a[href*="betting"]',
              'div[class*="overlay"]', 'div[class*="popup"]',
              'div[class*="modal"]', 'ins.adsbygoogle'
            ];
            adSelectors.forEach(function(sel) {
              document.querySelectorAll(sel).forEach(function(el) {
                if (el.tagName !== 'VIDEO' && el.tagName !== 'IFRAME' || 
                    (el.tagName === 'IFRAME' && el.src && !el.src.includes('vidsrc') && !el.src.includes('embed'))) {
                  el.style.display = 'none';
                }
              });
            });
          }, 500);
        })();
      ''');
    } catch (e) {
      debugPrint('JS injection error: $e');
    }
  }

  void _startTimeout() {
    _cancelTimeout();
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
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
    // إعادة قفل الشاشة على العمودي
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
                          const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'المصدر يبدو بطيئاً أو محظوراً',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'يمكنك فتح الرابط في المتصفح الخارجي، أو تجربة مصدر آخر.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
