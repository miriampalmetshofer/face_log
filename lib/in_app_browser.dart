import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppBrowser extends StatefulWidget {
  final String url;
  final VoidCallback onClose;

  const InAppBrowser({super.key, required this.url, required this.onClose});

  @override
  _InAppBrowserState createState() => _InAppBrowserState();
}

class _InAppBrowserState extends State<InAppBrowser> {
  InAppWebViewController? _webViewController;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-App-Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _webViewController?.goBack();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              _webViewController?.goForward();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webViewController?.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final url = await _webViewController?.getUrl();
              if (url != null) {
                final uri = Uri.parse(url.toString());
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
