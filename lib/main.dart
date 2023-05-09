import 'dart:async';
import 'dart:io';

import 'package:breaktest/test.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uni_links/uni_links.dart';

void main() {
  // runApp() 호출 전 Flutter SDK 초기화
  KakaoSdk.init(
    nativeAppKey: 'dde657c4208b924808f00c06180b432e',
  );

  runApp(
    const MaterialApp(
      home: WebViewApp(),
      // home: MyHomePage(),
    ),
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({Key? key}) : super(key: key);

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;
  late final PlatformWebViewControllerCreationParams params;
  StreamSubscription? _sub;

  void _handleIncomingLinks() {
    // It will handle app links while the app is already started - be it in
    // the foreground or in the background.
    _sub = uriLinkStream.listen((Uri? uri) {
      print('가가가가가가가가가가가가가가가가가가가가가가가가');
      if (!mounted) return;
      print('나나나나나나나나나나나나나나나나나나나나나나나나: ${uri?.queryParameters['url']}');

      Uri newUri = Uri.parse('https://${uri?.queryParameters['url']}');

      controller.loadRequest(newUri);
    }, onError: (Object err) {
      if (!mounted) return;
      print('다다다다다다다다다다다다다다다다다다다다다다다다: $err');
    });
  }

  @override
  void initState() {
    _handleIncomingLinks();

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    controller = WebViewController.fromPlatformCreationParams(params);

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
    }

    if (controller.platform is WebKitWebViewController) {
      (controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    // controller.loadRequest(Uri.parse('https://market-stage.break.co.kr'));
    controller.loadRequest(Uri.parse('http://192.168.0.93:3000/test'));
    // controller.loadRequest(Uri.parse('http://192.168.0.93:3000'));
    // controller.loadRequest(Uri.parse('http://172.30.1.22:3000/test'));

    controller.addJavaScriptChannel('openurl',
        onMessageReceived: (JavaScriptMessage message) {
      _launchUrl(message.message);
    });

    controller.addJavaScriptChannel('kakaologin',
        onMessageReceived: (JavaScriptMessage message) async {
      try {
        OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공 ${token.accessToken}');

        controller.runJavaScriptReturningResult('alerttest("${token}")');
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');

        try {
          OAuthToken token2 = await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공 ${token2.accessToken}');
          controller.runJavaScriptReturningResult(
              'alerttest("${token2.accessToken}")');
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
        }
      }
    });

    controller.addJavaScriptChannel('googlelogin',
        onMessageReceived: (JavaScriptMessage message) async {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      print('구글토큰 ${googleAuth?.accessToken}');

      controller.runJavaScriptReturningResult(
          'alerttest("${googleAuth?.accessToken}")');

      // controller.runJavaScript('alert("${googleAuth?.accessToken}")');
    });

    controller.addJavaScriptChannel('naverlogin',
        onMessageReceived: (JavaScriptMessage message) async {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      NaverAccessToken res = await FlutterNaverLogin.currentAccessToken;

      print('result = ${result}');
      print('res = ${res}');

      if (result.status == NaverLoginStatus.loggedIn) {
        print('accessToken = ${res.accessToken}');

        controller
            .runJavaScriptReturningResult('alerttest("${res.accessToken}")');
      }
    });

    controller.addJavaScriptChannel('share',
        onMessageReceived: (JavaScriptMessage message) async {
      print('message = ${message.message}');

      Share.share(message.message);
    });

    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _launchUrl(String urlParam) async {
    final url = Uri.parse(urlParam);
    if (await canLaunchUrl(url)) {
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          controller.goBack();
          return false;
        }
        bool result = await _showdialog(context);
        return result;
      },
      child: SafeArea(
        child: Scaffold(
            body: RefreshIndicator(
                onRefresh: () async {
                  await controller.reload();
                },
                child: WebViewWidget(controller: controller))),
      ),
    );
  }

  Future<dynamic> _showdialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('예')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아니오')),
        ],
      ),
    );
  }
}
