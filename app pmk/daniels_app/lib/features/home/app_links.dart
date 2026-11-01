import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLinks {
  static const webUrl = String.fromEnvironment('PMK_WEB_URL');

  static Future<void> openWebsite(BuildContext context) async {
    final uri = Uri.tryParse(webUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat Web PMK belum tersedia.')),
      );
      return;
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep the page available when the platform cannot launch a browser.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web PMK belum dapat dibuka. Coba lagi nanti.'),
        ),
      );
    }
  }
}
