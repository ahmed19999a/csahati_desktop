import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfActions {
  const PdfActions._();

  static Future<void> download(String url) async {
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched) throw Exception('تعذر فتح ملف PDF');
  }

  static Future<void> shareFile({
    required String url,
    required String fileName,
    String text = '',
  }) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر تجهيز ملف PDF للمشاركة');
    }
    final file = XFile.fromData(
      response.bodyBytes,
      name: fileName,
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([file], text: text);
  }
}
