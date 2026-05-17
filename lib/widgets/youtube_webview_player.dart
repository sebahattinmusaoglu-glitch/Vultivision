import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';


class YoutubeWebViewPlayer extends StatefulWidget {
  final String videoId;
  final VoidCallback? onVideoEnded;
  final VoidCallback? onError;
  final bool isActive;

  const YoutubeWebViewPlayer({
    super.key,
    required this.videoId,
    this.onVideoEnded,
    this.onError,
    this.isActive = true,
  });

  @override
  State<YoutubeWebViewPlayer> createState() => _YoutubeWebViewPlayerState();
}

class _YoutubeWebViewPlayerState extends State<YoutubeWebViewPlayer> {
  late final WebViewController _controller;

  static const _packageName = 'com.zennappstudio.vultivision';
  static const _origin = 'https://com.zennappstudio.vultivision';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();

    final controller = WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(_userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('youtube.com') ||
                request.url.contains('youtu.be') ||
                request.url.contains('doubleclick.net') ||
                request.url.contains('google.com') ||
                request.url.contains('about:blank') ||
                request.url.startsWith(_origin)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'VideoEvents',
        onMessageReceived: (message) {
          if (message.message == 'ended') {
            widget.onVideoEnded?.call();
          } else if (message.message.startsWith('error_')) {
            widget.onError?.call();
          }
        },
      )
      ..loadHtmlString(
        _buildHtml(widget.videoId),
        baseUrl: _origin,
      );
  }

  @override
  void didUpdateWidget(YoutubeWebViewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.runJavaScript('''
        var overlay = document.getElementById('overlay');
        if (overlay) { overlay.style.display = 'block'; overlay.style.opacity = '1'; }
      ''');      
      _controller.loadHtmlString(
        _buildHtml(widget.videoId),
        baseUrl: _origin);
    }
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.runJavaScript('if(player) player.pauseVideo();');
      } else {
        _controller.runJavaScript('if(player) player.playVideo();');
      }
    }
  }

  String _buildHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%;
      background: #000;
      overflow: hidden;
    }
    #player {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
    }

    #overlay {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      background: #000;
      z-index: 10;
      transition: opacity 0.3s ease;
    }


  </style>

</head>
<body>
  <div id="player"></div>
  <div id="overlay"></div>  
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    var player;
    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        videoId: '$videoId',
        playerVars: {
          autoplay: 1,
          controls: 0,
          playsinline: 1,
          rel: 0,
          modestbranding: 1,
          mute: 1,
          origin: '$_origin'
        },
        events: {
          onReady: function(event) {
            event.target.playVideo();
            setTimeout(function() {
              event.target.unMute();
              event.target.setVolume(100);
              var overlay = document.getElementById('overlay');
              overlay.style.opacity = '0';
              setTimeout(function() { overlay.style.display = 'none'; }, 800);
            }, 800);
          },
          onStateChange: function(event) {
            if (event.data === YT.PlayerState.ENDED) {
              VideoEvents.postMessage('ended');
            }
          },
          onError: function(event) {
            VideoEvents.postMessage('error_' + event.data);
          }
        }
      });
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}