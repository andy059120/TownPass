import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_web_view.dart';

/// 只載入獨立部署的 HTTPS 服務，不封裝網頁或照護規則。
class CarePassView extends StatelessWidget {
  static const String configuredUrl = String.fromEnvironment(
    'CAREPASS_URL',
    defaultValue: 'https://townpass2026-starter.vercel.app/#home',
  );

  final String serviceUrl;

  const CarePassView({super.key, this.serviceUrl = configuredUrl});

  static Uri? parseServiceUrl(String value) {
    final uri = Uri.tryParse(value);
    if (value.contains(RegExp(r'\s')) ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  @override
  Widget build(BuildContext context) {
    final uri = parseServiceUrl(serviceUrl);
    if (uri == null) {
      return Scaffold(
        appBar: TPAppBar(
          title: '照護通 CarePass',
          backgroundColor: TPColors.primary500,
          foregroundColor: TPColors.white,
          leading: const SizedBox.shrink(),
          actions: [CloseButton(onPressed: () => Get.back())],
        ),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('照護通服務尚未設定，請聯絡服務提供者。', textAlign: TextAlign.center),
            ),
          ),
        ),
      );
    }
    return TPWebView(
      initialArgument: WebViewArgument(
        url: uri.toString(),
        forceTitle: '照護通 CarePass',
      ),
      loadErrorMessage: '目前無法載入照護通，請確認網路連線後再試一次。',
    );
  }
}
