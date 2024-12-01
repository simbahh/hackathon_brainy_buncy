import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../constants/app_colors.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final Quiz quiz;

  const ResultScreen({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.quiz,
  }) : super(key: key);

  String _getResultMessage(double percentage) {
    if (percentage >= 90) return 'Outstanding!';
    if (percentage >= 80) return 'Excellent!';
    if (percentage >= 70) return 'Good Job!';
    if (percentage >= 60) return 'Keep Improving!';
    return 'Keep Practicing!';
  }

  String _getSubMessage(double percentage) {
    if (percentage >= 70) {
      return 'You\'ve mastered this quiz!';
    } else if (percentage >= 50) {
      return 'You\'re making good progress!';
    } else {
      return 'Don\'t give up, try again!';
    }
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 70) return AppColors.success;
    if (percentage >= 50) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage based on quiz mode
    final double percentage = (score / totalQuestions) * 100;
    final bool isPassing = percentage >= 70;
    final Color scoreColor = _getScoreColor(percentage);
    final String resultMessage = _getResultMessage(percentage);
    final String subMessage = _getSubMessage(percentage);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header with Quiz Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.subject.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        (() {
                          switch (quiz.mode) {
                            case QuizMode.multipleChoice:
                              return 'Multiple Choice';
                            case QuizMode.trueFalse:
                              return 'True/False';
                            case QuizMode.openEnded:
                              return 'Open Ended';
                          }
                        })(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'QUIZ COMPLETED',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Score Circle with animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: percentage),
                      duration: Duration(seconds: 1),
                      builder: (context, double value, child) {
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scoreColor,
                              width: 8,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$score/$totalQuestions',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor,
                                  ),
                                ),
                                Text(
                                  '${value.round()}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 40),

                    // Result Message
                    Text(
                      resultMessage,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),

                    SizedBox(height: 16),

                    Text(
                      subMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: AppColors.buttonText,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 56),
                    ),
                    child: Text(
                      'Start New',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      // Add share functionality here
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 56),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Share Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
