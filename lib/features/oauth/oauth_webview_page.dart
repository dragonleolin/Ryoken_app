import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 簡單的 OAuth WebView：
/// 1. 開啟後端 /oauth2/authorization/{provider}
/// 2. 監聽最終導回含 token 的 URL (例如 http://localhost:8080/oauth2/success?token=...)
/// 3. 抓到 token 後 pop 回傳
class OAuthWebViewPage extends StatefulWidget {
  final String authUrl;
  final String successPath; // 預設：/oauth2/success

  const OAuthWebViewPage({
    super.key,
    required this.authUrl,
    this.successPath = '/oauth2/success',
  });

  @override
  State<OAuthWebViewPage> createState() => _OAuthWebViewPageState();
}

class _OAuthWebViewPageState extends State<OAuthWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            final uri = Uri.parse(req.url);
            if (uri.path == widget.successPath &&
                uri.queryParameters['token'] != null) {
              Navigator.pop(context, uri.queryParameters['token']);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  /// 處理返回邏輯：
  /// - 如果 WebView 有上一頁，先 goBack()
  /// - 否則直接 pop 當前頁面
  Future<bool> _handleWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // 阻止直接退出頁面
    }
    return true; // 允許退出
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OAuth 認證'),
          backgroundColor: const Color(0xFF0C0C0C),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
