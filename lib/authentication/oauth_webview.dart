import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import 'auth_provider.dart';

class OAuthWebView extends StatefulWidget {
  final String authUrl;
  final String provider;

  const OAuthWebView({
    super.key,
    required this.authUrl,
    required this.provider,
  });

  @override
  State<OAuthWebView> createState() => _OAuthWebViewState();
}

class _OAuthWebViewState extends State<OAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            // Check if this is our callback URL with token parameters
            if (request.url.contains('/auth/callback?token=')) {
              _handleAuthCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  Future<void> _handleAuthCallback(String url) async {
    final success = await AuthService.handleAuthCallback(url);

    if (success && mounted) {
      // Get the auth provider and update authentication state
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Extract token from URL and set authenticated
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];

      if (token != null) {
        await authProvider.setAuthenticated(token);
      }

      // Navigate back to the app
      Navigator.of(context).pop(true); // Return success
    } else {
      // Handle authentication failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false); // Return failure
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.provider} Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}