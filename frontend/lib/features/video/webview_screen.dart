import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final List<String> urls;

  const WebViewScreen({super.key, required this.title, required this.urls});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _fallbackTimer;

  // كود الجافاسكريبت لحظر الإعلانات والنوافذ المنبثقة
  final String _adBlockScript = """
    (function() {
        // 1. منع النوافذ المنبثقة (Pop-ups)
        window.open = function() { return null; };
        window.alert = function() { return null; };
        
        // 2. إخفاء الإعلانات المعروفة (Ad Banners)
        setInterval(function() {
            var adSelectors = [
                'iframe[src*="ad"]', 'iframe[src*="banner"]', 
                'div[class*="ad-"]', 'div[id*="ad-"]', 
                '.adsbygoogle', 'a[href*="betting"]',
                'div[class*="overlay"]', 'div[class*="popup"]'
            ];
            adSelectors.forEach(function(sel) {
                var elems = document.querySelectorAll(sel);
                for (var i = 0; i < elems.length; i++) {
                    // إخفاء العنصر مع إبقاء مساحة المشاهدة سليمة
                    if(elems[i].tagName !== 'VIDEO') {
                        elems[i].style.display = 'none';
                    }
                }
            });
        }, 1000);
    })();
  """;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
            _startFallbackTimer();
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
              _injectAdBlockerAndCheck();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // 3. منع الروابط الخارجية والإعلانات التي تحاول فتح المتصفح أو التطبيقات
            if (request.url.startsWith('intent://') || 
                request.url.contains('play.google.com') || 
                request.url.contains('apps.apple.com') ||
                request.url.contains('about:blank')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: \${error.description}');
            _nextSource(); 
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.urls[_currentIndex]));
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        _nextSource();
      }
    });
  }

  // حقن كود حظر الإعلانات والتحقق من وجود الفيديو
  void _injectAdBlockerAndCheck() async {
    _fallbackTimer?.cancel();
    try {
      // حقن مانع الإعلانات
      await _controller.runJavaScript(_adBlockScript);

      // فحص ما إذا كانت الصفحة تحتوي على الفيديو أم لا
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var text = document.body.innerText.toLowerCase();
          var hasVideo = document.querySelector('video') !== null || document.querySelector('iframe') !== null;
          if (!hasVideo || text.includes('not found') || text.includes('404') || text.includes('error')) {
            return 'error';
          }
          return 'success';
        })();
      ''');
      
      if (result.toString().contains('error')) {
        _nextSource();
      }
    } catch (e) {
      debugPrint('JS injection failed: \$e');
    }
  }

  void _nextSource() {
    if (!mounted) return;
    
    _fallbackTimer?.cancel();

    if (_currentIndex < widget.urls.length - 1) {
      setState(() {
        _currentIndex++;
        _isLoading = true;
      });
      _initWebView();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذراً، لم نجد مصدراً يعمل لهذا الفيلم حالياً. جرب فيلماً آخر.'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'المصدر \${_currentIndex + 1}/\${widget.urls.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('جاري البحث عن مصدر يعمل...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
