import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const String _realUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  static const List<String> _blockedHosts = [
    'google.com', 'google.co', 'bing.com', 'yahoo.com', 'duckduckgo.com',
    'yandex.com', 'baidu.com', 'play.google.com', 'apps.apple.com',
    'instagram.com', 'facebook.com', 'twitter.com', 'tiktok.com',
    'doubleclick.net', 'googlesyndication.com', 'googletagmanager.com',
    'google-analytics.com', 'propellerads.com', 'popads.net',
    'adsterra.com', 'onclickads.net',
  ];

  bool _isBlocked(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      if (host.isEmpty) return false;
      for (final blocked in _blockedHosts) {
        if (host == blocked || host.endsWith('.$blocked')) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
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
            // إعادة حقن الكود كل ثانية لمدة 10 ثوانٍ لضمان نجاحه
            for (int i = 1; i <= 10; i++) {
              Future.delayed(Duration(seconds: i), () {
                _injectAntiRedirectScript();
              });
            }
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
            _cancelTimeout();
          },
          onNavigationRequest: (request) {
            if (_isBlocked(request.url)) return NavigationDecision.prevent;
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

  Future<void> _injectAntiRedirectScript() async {
    try {
      await _controller.runJavaScript('''
        (function() {
          try {
            // 1. منع النوافذ المنبثقة
            window.open = function() { return null; };
            window.alert = function() { return null; };
            window.confirm = function() { return false; };
            
            // 2. إجبار الصوت على العمل (الحل الجذري)
            var videos = document.querySelectorAll('video, audio');
            videos.forEach(function(v) {
              v.muted = false;         // إلغاء الكتم
              v.volume = 1.0;           // رفع الصوت إلى 100%
              v.defaultMuted = false;   // منع الكتم الافتراضي
              v.removeAttribute('muted');
              if (v.paused) {
                v.play().catch(function(e) {});
              }
            });
            
            // 3. البحث عن أزرار التشغيل والضغط عليها
            var playSelectors = [
              '.play-button', '.vjs-big-play-button', '.jw-icon-playback',
              '[aria-label*="Play"]', '[aria-label*="play"]',
              'button[title*="Play"]', '.play', '.btn-play'
            ];
            playSelectors.forEach(function(sel) {
              var btn = document.querySelector(sel);
              if (btn && btn.offsetParent !== null) {
                btn.click();
              }
            });
            
            // 4. منع التوجيه لصفحات البحث
            document.addEventListener('click', function(e) {
              var t = e.target.closest('a');
              if (t && t.href) {
                var h = t.href.toLowerCase();
                if (h.includes('google') || h.includes('bing') || h.includes('yahoo')) {
                  e.preventDefault();
                  e.stopPropagation();
                }
              }
            }, true);
            
            // 5. إخفاء الإعلانات
            var adSel = ['iframe[src*="ad"]', 'div[class*="ad-"]', '.adsbygoogle', 'ins.adsbygoogle'];
            adSel.forEach(function(sel) {
              document.querySelectorAll(sel).forEach(function(el) {
                if (el.tagName !== 'VIDEO') el.style.display = 'none';
              });
            });
          } catch(e) {}
        })();
      ''');
    } catch (e) {
      debugPrint('JS injection error: $e');
    }
  }

  // زر يدوي لرفع الصوت (في حال فشل الكود التلقائي)
  Future<void> _forceUnmute() async {
    try {
      await _controller.runJavaScript('''
        (function() {
          var videos = document.querySelectorAll('video, audio');
          videos.forEach(function(v) {
            v.muted = false;
            v.volume = 1.0;
            if (v.paused) v.play().catch(function(){});
          });
          return 'ok';
        })();
      ''');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 تم تفعيل الصوت'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تفعيل الصوت: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _startTimeout() {
    _cancelTimeout();
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _isLoading) setState(() => _showTimeoutHelp = true);
    });
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (mounted && _showTimeoutHelp) setState(() => _showTimeoutHelp = false);
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
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
          title: Text(widget.title, style: const TextStyle(fontSize: 14)),
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
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'تفعيل الصوت',
              onPressed: _forceUnmute,
            ),
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
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.transparent,
                ),
              ),
            if (_showTimeoutHelp)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_off_rounded, color: AppColors.warning, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'لا يوجد صوت؟',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'اضغط على زر الصوت في الأعلى. إذا استمرت المشكلة، جرب مصدراً آخر.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _forceUnmute,
                            icon: const Icon(Icons.volume_up_rounded),
                            label: const Text('تفعيل الصوت الآن'),
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
