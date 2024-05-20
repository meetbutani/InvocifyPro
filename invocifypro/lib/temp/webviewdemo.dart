import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewDemo extends StatefulWidget {
  const WebViewDemo({super.key});

  @override
  State<WebViewDemo> createState() => _WebViewDemoState();
}

class _WebViewDemoState extends State<WebViewDemo> {
  HeadlessInAppWebView? headlessWebView;
  PullToRefreshController? pullToRefreshController;
  InAppWebViewController? webViewController;

  String url = "";
  int progress = 0;
  bool convertFlag = false;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
          url: WebUri(
              "https://www.gs1.org/services/verified-by-gs1/results?gtin=8906010500375")),
      initialSettings: InAppWebViewSettings(isInspectable: kDebugMode),
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        webViewController = controller;

        const snackBar = SnackBar(
          content: Text('HeadlessInAppWebView created!'),
          duration: Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      onLoadStart: (controller, url) async {
        setState(() {
          this.url = url?.toString() ?? '';
        });
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          this.progress = progress;
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          this.url = url?.toString() ?? '';
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    headlessWebView?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        "HeadlessInAppWebView to InAppWebView",
      )),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Text(
                "URL: ${(url.length > 40) ? "${url.substring(0, 40)}..." : url} - $progress%"),
          ),
          !convertFlag
              ? Center(
                  child: ElevatedButton(
                      onPressed: () async {
                        var headlessWebView = this.headlessWebView;
                        if (headlessWebView != null &&
                            !headlessWebView.isRunning()) {
                          await headlessWebView.run();
                        }
                      },
                      child: const Text("Run HeadlessInAppWebView")),
                )
              : Container(),
          !convertFlag
              ? Center(
                  child: ElevatedButton(
                      onPressed: () {
                        if (!convertFlag) {
                          setState(() {
                            convertFlag = true;
                          });
                        }
                      },
                      child: const Text("Convert to InAppWebView")),
                )
              : Container(),
          convertFlag
              ? Expanded(
                  child: InAppWebView(
                    headlessWebView: headlessWebView,
                    onWebViewCreated: (controller) {
                      headlessWebView = null;
                      webViewController = controller;

                      

                      const snackBar = SnackBar(
                        content: Text(
                            'HeadlessInAppWebView converted to InAppWebView!'),
                        duration: Duration(seconds: 1),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url?.toString() ?? "";
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController?.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress;
                      });
                    },
                    onLoadStop: (controller, url) {
                      pullToRefreshController?.endRefreshing();
                      setState(() {
                        this.url = url?.toString() ?? "";
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      pullToRefreshController?.endRefreshing();
                    },
                  ),
                )
              : Container()
        ],
      ),
    );
  }
}
