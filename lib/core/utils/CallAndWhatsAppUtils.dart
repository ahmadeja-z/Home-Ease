import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class CallAndWhatsAppUtils {
  /// -------------------------
  /// 📞 OPEN PHONE DIALER
  /// -------------------------
  static Future<void> openDialer(String number) async {
    if (number.isEmpty) {
      debugPrint("❌ No phone number provided!");
      return;
    }

    final Uri dialUri = Uri(scheme: "tel", path: number);

    if (await canLaunchUrl(dialUri)) {
      await launchUrl(dialUri);
    } else {
      debugPrint("❌ Cannot open dialer!");
    }
  }

  /// -------------------------
  /// 🟢 OPEN WHATSAPP CHAT
  /// -------------------------
  static Future<void> openWhatsAppChat({
    required String? whatsappNumber,
    String message = "",
    VoidCallback? onError,
  }) async {
    // If number is missing → show error
    if (whatsappNumber == null || whatsappNumber.isEmpty) {
      if (onError != null) onError();
      debugPrint("❌ WhatsApp number missing!");
      return;
    }

    final encodedMessage = Uri.encodeComponent(message);
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$whatsappNumber?text=$encodedMessage",
    );
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (onError != null) onError();
      debugPrint("❌ Cannot open WhatsApp!");
    }
  }
}
