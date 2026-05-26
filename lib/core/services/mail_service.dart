import 'package:url_launcher/url_launcher.dart';

class MailService {
  static Future<void> sendMail({
    required String subject,
    required String body,
    String to = 'ahmad.ejaz.dev@gmail.com',
  }) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: to,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    if (await canLaunchUrl(params)) {
      await launchUrl(params, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $params';
    }
  }

  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
