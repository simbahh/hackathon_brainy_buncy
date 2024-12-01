import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HintSection extends StatelessWidget {
  final String? currentHint;
  final bool isLoadingHint;
  final VoidCallback onGetHint;

  const HintSection({
    Key? key,
    required this.currentHint,
    required this.isLoadingHint,
    required this.onGetHint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoadingHint)
          Center(child: CircularProgressIndicator())
        else if (currentHint != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary),
            ),
            child: Text(
              currentHint!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ElevatedButton.icon(
          icon: const Icon(Icons.lightbulb_outline),
          label: Text(currentHint == null ? 'Hint?' : 'Another hint?'),
          onPressed: isLoadingHint ? null : onGetHint,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.buttonText,
            padding: EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
