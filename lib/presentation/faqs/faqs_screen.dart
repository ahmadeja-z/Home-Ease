import 'package:flutter/material.dart';
import 'package:homeease/core/utils/labels.dart';
import 'package:homeease/widgets/custom_app_bar.dart';

import '../../widgets/faqs_expention_tile.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> with TickerProviderStateMixin {
  final List<Faq> faqs = [
    Faq(
      question: Labels.faqHowToOrder,
      answer: Labels.faqHowToOrderAnswer,
      icon: Icons.shopping_bag_outlined,
    ),
    Faq(
      question: Labels.faqTrackOrder,
      answer: Labels.faqTrackOrderAnswer,
      icon: Icons.local_shipping_outlined,
    ),
    Faq(
      question: Labels.faqDeliveryTime,
      answer: Labels.faqDeliveryTimeAnswer,
      icon: Icons.access_time_outlined,
    ),
    Faq(
      question: Labels.faqPaymentMethods,
      answer: Labels.faqPaymentMethodsAnswer,
      icon: Icons.payment_outlined,
    ),
    Faq(
      question: Labels.faqCancelOrder,
      answer: Labels.faqCancelOrderAnswer,
      icon: Icons.cancel_outlined,
    ),
    Faq(
      question: Labels.faqWrongOrDamaged,
      answer: Labels.faqWrongOrDamagedAnswer,
      icon: Icons.report_problem_outlined,
    ),
    Faq(
      question: Labels.faqDeliveryCharges,
      answer: Labels.faqDeliveryChargesAnswer,
      icon: Icons.local_atm_outlined,
    ),
    Faq(
      question: Labels.faqUpdateAddress,
      answer: Labels.faqUpdateAddressAnswer,
      icon: Icons.location_on_outlined,
    ),
    Faq(
      question: Labels.faqSecurePayments,
      answer: Labels.faqSecurePaymentsAnswer,
      icon: Icons.security_outlined,
    ),
    Faq(
      question: Labels.faqDeliverToMyArea,
      answer: Labels.faqDeliverToMyAreaAnswer,
      icon: Icons.map_outlined,
    ),
    Faq(
      question: Labels.faqCustomerSupport,
      answer: Labels.faqCustomerSupportAnswer,
      icon: Icons.support_agent_outlined,
    ),
  ];

  int? _expandedIndex;
  final Map<int, AnimationController> _controllers = {};
  final Map<int, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < faqs.length; i++) {
      _controllers[i] = AnimationController(
        duration: const Duration(milliseconds: 350),
        vsync: this,
      );
      _animations[i] = CurvedAnimation(
        parent: _controllers[i]!,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleExpansion(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _controllers[index]!.reverse();
        _expandedIndex = null;
      } else {
        if (_expandedIndex != null) {
          _controllers[_expandedIndex!]!.reverse();
        }
        _controllers[index]!.forward();
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(title: Labels.helpAndSupport),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          final isExpanded = _expandedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumFaqTile(
              faq: faq,
              isExpanded: isExpanded,
              animation: _animations[index]!,
              onTap: () => _toggleExpansion(index),
            ),
          );
        },
      ),
    );
  }
}

class Faq {
  final String? question;
  final String? answer;
  final IconData icon;

  Faq({this.question, this.answer, required this.icon});
}
