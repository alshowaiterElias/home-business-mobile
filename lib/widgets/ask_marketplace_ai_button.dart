import 'package:flutter/material.dart';
import 'package:home_business_mobile/screens/ai/marketplace_assistant_sheet.dart';

class AskMarketplaceAiButton extends StatelessWidget {
  final Map<String, dynamic> contextData;

  const AskMarketplaceAiButton({Key? key, required this.contextData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'ai_assistant_btn',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => MarketplaceAssistantSheet(contextData: contextData),
        );
      },
      icon: const Icon(Icons.auto_awesome),
      label: const Text('مساعد الذكاء الاصطناعي'),
      backgroundColor: Colors.purple.shade700,
    );
  }
}
