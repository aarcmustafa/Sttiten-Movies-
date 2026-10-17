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

  final String _adBlockScript = """
    (function() {
        window.open = function() { return null; };
        window.alert = function() { return null; };
        setInterval(function() {
            var adSelectors = ['iframe[src*="ad"]', 'div[class*="ad-"]', '.adsbygoogle', 'a[href*="betting"]', 'div[class*="popup"]'];
            adSelectors.forEach(function(sel) {
                var elems = document.querySelectorAll(sel);
                for (var i = 0; i < elems.length; i++) {
                    if(elems[i].tagName !== 'VIDEO') elems[i].style.display = 'none';
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
            // نبدأ المؤقت عند بدء التحميل
            _startFallbackTimer();
          },
          onPageFinished: (String url) async {
            // ننتظر قليلاً ليقوم السكريبت داخل الموقع بتحميل الفيديو
            await Future.delayed(const Duration(seconds: 2));
            _injectAdBlockerAndCheck();
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('intent://') || 
                request.url.contains('play.google.com') || 
                request.url.contains('apps.apple.com')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            _nextSource(); 
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.urls[_currentIndex]));
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    // إذا لم يتم العثور على فيديو خلال 12 ثانية، ننتقل للمصدر التالي
    _fallbackTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _isLoading) {
        _nextSource();
      }
    });
  }

  void _injectAdBlockerAndCheck() async {
    try {
      await _controller.runJavaScript(_adBlockScript);

      // فحص دقيق: هل يوجد فيديو جاهز؟
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var video = document.querySelector('video');
          var iframe = document.querySelector('iframe');
          var text = document.body.innerText.toLowerCase();
          
          // إذا وجدنا فيديو أو إطار فيديو، ولم تكن الصفحة تحتوي على "not found"
          if ((video || iframe) && !text.includes('not found') && !text.includes('404')) {
            return 'success';
          }
          return 'error';
        })();
      ''');
      
      if (result.toString().contains('success')) {
        // نجحنا! نلغي المؤقت ونخفي شاشة التحميل
        _fallbackTimer?.cancel();
        if (mounted) setState(() => _isLoading = false);
      } else {
        // لم يجد فيديو، ينتقل للخلفية
        _nextSource();
      }
    } catch (e) {
      _nextSource();
    }
  }

  void _nextSource() {
    if (!mounted) return;
    
    _fallbackTimer?.cancel();

    if (_currentIndex < widget.urls.length - 1) {
      setState(() {
        _currentIndex++;
        // نُبقي شاشة التحميل ظاهرة
        _isLoading = true;
      });
      _initWebView(); // تحميل المصدر التالي في الخلفية
    } else {
      // فشلت كل المصادر
      if (mounted) {
        setState(() => _isLoading = false); // نُظهر الشاشة السوداء
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عذراً، لم نجد رابطاً يعمل لهذا الفيلم حالياً.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // الخروج للشاشة السابقة
      }
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
      ),
      body: Stack(
        children: [
          // الـ WebView يعمل في الخلفية دائماً
          WebViewWidget(controller: _controller),
          
          // شاشة التحميل الأنيقة التي تغطي الـ WebView
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: AppColors.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'جاري تجهيز الفيلم بأفضل جودة...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
