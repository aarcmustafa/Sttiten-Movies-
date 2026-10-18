import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants.dart';

class QissatIshqScreen extends StatefulWidget {
  final String? searchQuery;

  const QissatIshqScreen({super.key, this.searchQuery});

  @override
  State<QissatIshqScreen> createState() => _QissatIshqScreenState();
}

class _QissatIshqScreenState extends State<QissatIshqScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    String url = 'https://3sk.tv';
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      url = 'https://3sk.tv/?s=${Uri.encodeComponent(widget.searchQuery!)}';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _injectAdBlocker();
          },
          onNavigationRequest: (request) {
            final blockedHosts = ['google.com', 'play.google.com', 'facebook.com', 'doubleclick.net'];
            for (final host in blockedHosts) {
              if (request.url.contains(host)) return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _injectAdBlocker() async {
    try {
      await _controller.runJavaScript('''
        (function() {
          window.open = function() { return null; };
          window.alert = function() { return null; };
          setInterval(function() {
            var adSelectors = ['iframe[src*="ad"]', 'div[class*="ad-"]', '.adsbygoogle', 'ins.adsbygoogle'];
            adSelectors.forEach(function(sel) {
              document.querySelectorAll(sel).forEach(function(el) {
                if (el.tagName !== 'VIDEO') el.style.display = 'none';
              });
            });
          }, 500);
        })();
      ''');
    } catch (e) {
      debugPrint('JS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.searchQuery != null ? 'قصة عشق: ${widget.searchQuery}' : 'قصة عشق'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}
