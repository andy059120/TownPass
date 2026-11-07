import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/carepass/carepass_view.dart';
import 'package:town_pass/page/city_service/model/my_service_model.dart';
import 'package:town_pass/page/city_service/model/trending_service_model.dart';
import 'package:town_pass/util/tp_route.dart';
import 'package:town_pass/util/tp_web_view.dart';

class _WebViewController extends Fake implements InAppWebViewController {
  int loads = 0;
  String? lastUrl;

  @override
  Future<void> loadUrl({
    required URLRequest urlRequest,
    Uri? iosAllowingReadAccessTo,
    WebUri? allowingReadAccessTo,
  }) async {
    loads++;
    lastUrl = urlRequest.url.toString();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('照護通的服務入口與熱門捷徑指向已註冊的路由', () {
    final service = MyServiceItemId.carePass.item;
    final uri = Uri.parse(service.destinationUrl);
    expect(service.category, MyServiceCategory.healthCare);
    expect(service.title, '照護通');
    expect(uri.scheme, 'local');
    expect('/${uri.host}', TPRoute.carePass);
    expect(TPRoute.page.any((page) => page.name == TPRoute.carePass), isTrue);
    expect(
      TrendingServiceModel.serviceList.any(
        (item) => item.url == service.destinationUrl,
      ),
      isTrue,
    );
  });

  test('服務網址只接受具備主機且沒有帳密的 HTTPS 網址', () {
    for (final invalid in [
      '',
      'http://carepass.example.com/',
      'file:///carepass/index.html',
      'local://carepass',
      'https://',
      'https://user:password@carepass.example.com/',
      'https://carepass.example.com/invalid path',
    ]) {
      expect(CarePassView.parseServiceUrl(invalid), isNull, reason: invalid);
    }
    expect(
      CarePassView.parseServiceUrl('https://carepass.example.com/'),
      Uri.parse('https://carepass.example.com/'),
    );
  });

  testWidgets('缺少或無效的服務網址會提示，並且不建立 WebView', (tester) async {
    for (final invalid in ['', 'http://carepass.example.com/']) {
      await tester.pumpWidget(
        GetMaterialApp(home: CarePassView(serviceUrl: invalid)),
      );
      expect(find.text('照護通服務尚未設定，請聯絡服務提供者。'), findsOneWidget);
      expect(find.byType(TPWebView), findsNothing);
    }
  });

  testWidgets('設定的 HTTPS 網址直接傳給 WebView，並啟用載入失敗提示', (tester) async {
    late Widget view;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            view = const CarePassView().build(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(view, isA<TPWebView>());
    final webView = view as TPWebView;
    expect(
      webView.initialArgument?.url,
      'https://townpass2026-starter.vercel.app/#home',
    );
    expect(webView.initialArgument?.forceTitle, '照護通 CarePass');
    expect(webView.loadErrorMessage, isNotEmpty);
  });

  testWidgets('local URI 導覽能開啟照護通路由並返回', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: Text('服務首頁')),
        getPages: [
          GetPage(
            name: TPRoute.carePass,
            page: () => const CarePassView(serviceUrl: ''),
          ),
        ],
      ),
    );
    final navigation = TPRoute.openUri(uri: 'local://carepass');
    await tester.pumpAndSettle();
    expect(find.text('照護通服務尚未設定，請聯絡服務提供者。'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await navigation;
    expect(find.text('服務首頁'), findsOneWidget);
  });

  testWidgets('主頁錯誤可重試，子資源錯誤及取消導覽不遮住網頁', (tester) async {
    final view = TPWebView(
      initialArgument: const WebViewArgument(
        url: 'https://carepass.example.com/',
        forceTitle: '照護通 CarePass',
      ),
      loadErrorMessage: '目前無法載入照護通',
    );
    late TPInAppWebView native;
    // 只掛載錯誤提示層，以可控制的 controller 模擬原生回呼。
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final scaffold = view.build(context) as Scaffold;
            final stack = scaffold.body! as Stack;
            native = stack.children.first as TPInAppWebView;
            return Stack(
              fit: StackFit.expand,
              children: stack.children.skip(1).toList(),
            );
          },
        ),
      ),
    );
    final controller = _WebViewController();
    native.onWebViewCreated!(controller);
    await tester.pump();
    expect(controller.loads, 1);
    final mainRequest = WebResourceRequest(
      url: WebUri('https://carepass.example.com/'),
      isForMainFrame: true,
    );
    native.onReceivedError!(
      controller,
      WebResourceRequest(
        url: WebUri('https://carepass.example.com/favicon.ico'),
        isForMainFrame: false,
      ),
      WebResourceError(
        type: WebResourceErrorType.HOST_LOOKUP,
        description: 'DNS',
      ),
    );
    native.onReceivedError!(
      controller,
      mainRequest,
      WebResourceError(type: WebResourceErrorType.CANCELLED, description: '取消'),
    );
    await tester.pump();
    expect(find.text('重新載入'), findsNothing);

    native.onReceivedError!(
      controller,
      mainRequest,
      WebResourceError(
        type: WebResourceErrorType.HOST_LOOKUP,
        description: 'DNS',
      ),
    );
    await tester.pump();
    expect(find.text('目前無法載入照護通'), findsOneWidget);
    await tester.tap(find.text('重新載入'));
    await tester.pump();
    expect(controller.loads, 2);
    expect(controller.lastUrl, 'https://carepass.example.com/');
    expect(find.text('目前無法載入照護通'), findsNothing);

    native.onReceivedHttpError!(
      controller,
      mainRequest,
      WebResourceResponse(statusCode: 503),
    );
    await tester.pump();
    expect(find.text('目前無法載入照護通'), findsOneWidget);
  });
}
