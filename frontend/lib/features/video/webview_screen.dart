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
              _checkIfVideoExists();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: \${error.description}');
            _nextSource(); // في حال فشل الاتصال بالموقع نهائياً
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.urls[_currentIndex]));
  }

  // مؤقت: إذا استغرق التحميل أكثر من 8 ثوانٍ، ننتقل للمصدر التالي
  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        _nextSource();
      }
    });
  }

  // فحص الصفحة: إذا كانت تحتوي على كلمة "not found" أو فارغة، ننتقل تلقائياً
  void _checkIfVideoExists() async {
    _fallbackTimer?.cancel();
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var text = document.body.innerText.toLowerCase();
          if (text.includes('not found') || text.includes('404') || text.includes('error') || text.length < 50) {
            return 'error';
          }
          return 'success';
        })();
      ''');
      
      if (result.toString().contains('error')) {
        _nextSource();
      }
    } catch (e) {
      debugPrint('JS check failed: \$e');
    }
  }

  // الانتقال للمصدر التالي
  void _nextSource() {
    if (!mounted) return;
    
    _fallbackTimer?.cancel();

    if (_currentIndex < widget.urls.length - 1) {
      setState(() {
        _currentIndex++;
        _isLoading = true;
      });
      _initWebView(); // إعادة تحميل المشغل بالرابط الجديد
    } else {
      // إذا فشلت جميع المصادر
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذراً، لم يتم العثور على مصدر يعمل لهذا الفيلم حالياً.'),
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
