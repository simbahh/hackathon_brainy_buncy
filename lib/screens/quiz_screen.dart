import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../constants/app_colors.dart';
import '../components/quiz_timer.dart';
import '../utils/quiz_service.dart';
import '../components/hint_section.dart';
import '../components/explanation_section.dart';
import 'package:speech_to_text/speech_to_text.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final List<Question> questions;

  const QuizScreen({
    Key? key,
    required this.quiz,
    required this.questions,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  String? selectedAnswer;
  final TextEditingController _answerController = TextEditingController();
  bool? _isAnswerCorrect;
  String? currentHint;
  bool isLoadingHint = false;
  int hintCount = 0;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Time\'s Up!'),
        content: Text('Your time has expired.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _finishQuiz();
            },
            child: Text('See Results'),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
    });
  }

  Future<void> _nextQuestion() async {
    if (widget.quiz.mode != QuizMode.openEnded) {
      if (selectedAnswer != null &&
          selectedAnswer ==
              widget.questions[currentQuestionIndex].correctAnswer) {
        setState(() {
          score++;
        });
      }
    }

    setState(() {
      currentQuestionIndex++;
      selectedAnswer = null;
      _isAnswerCorrect = null;
      _answerController.clear();
      currentHint = null;
      hintCount = 0;
    });
  }

  void _previousQuestion() {
    setState(() {
      currentQuestionIndex--;
      selectedAnswer = widget.questions[currentQuestionIndex].selectedAnswer;
    });
  }

  void _finishQuiz() {
    if (widget.quiz.mode != QuizMode.openEnded) {
      if (selectedAnswer != null &&
          selectedAnswer ==
              widget.questions[currentQuestionIndex].correctAnswer) {
        setState(() {
          score++;
        });
      }
    }

    Navigator.pushReplacementNamed(
      context,
      '/result',
      arguments: {
        'score': score,
        'totalQuestions': widget.questions.length,
        'quiz': widget.quiz,
      },
    );
  }

  Future<void> _showQuitDialog(BuildContext context) async {
    final bool? quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quit Quiz?'),
        content:
            Text('Are you sure you want to quit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Quit'),
          ),
        ],
      ),
    );

    if (quit == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitOpenEndedAnswer() async {
    FocusScope.of(context).unfocus();

    try {
      final isCorrect = await QuizService.evaluateOpenEndedAnswer(
        widget.questions[currentQuestionIndex].question,
        _answerController.text,
        widget.questions[currentQuestionIndex].correctAnswer,
      );

      setState(() {
        _isAnswerCorrect = isCorrect;
        selectedAnswer = _answerController.text;
        if (isCorrect) score++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error evaluating answer: $e')),
      );
    }
  }

  Future<void> _getHint() async {
    setState(() {
      isLoadingHint = true;
      hintCount++;
    });

    try {
      final hint = await QuizService.getHint(
        question: widget.questions[currentQuestionIndex].question,
        correctAnswer: widget.questions[currentQuestionIndex].correctAnswer,
        hintCount: hintCount,
      );
      setState(() {
        currentHint = hint;
        isLoadingHint = false;
      });
    } catch (e) {
      setState(() => isLoadingHint = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get hint')),
      );
    }
  }

  Future<void> _toggleListening() async {
    try {
      bool available = await _speech.initialize(
        onError: (error) {
          print('Error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech recognition error: $error')),
          );
        },
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );

      if (available) {
        if (_isListening) {
          setState(() => _isListening = false);
          await _speech.stop();
        } else {
          setState(() => _isListening = true);
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _answerController.text = result.recognizedWords;
                _answerController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _answerController.text.length),
                );
              });
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available on this device')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing speech recognition: $e')),
      );
    }
  }

  Widget _buildQuestionContent() {
    if (widget.quiz.mode == QuizMode.openEnded) {
      return Column(
        children: [
          Text(
            widget.questions[currentQuestionIndex].question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            decoration: InputDecoration(
                              hintText: 'Type your answer...',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                            maxLines: 1,
                            textInputAction: TextInputAction.done,
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color:
                                _isListening ? AppColors.primary : Colors.grey,
                          ),
                          onPressed: _toggleListening,
                        ),
                        Container(
                          height: 56,
                          child: TextButton(
                            onPressed: _answerController.text.trim().isEmpty
                                ? null
                                : _submitOpenEndedAnswer,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.buttonText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(10),
                                ),
                              ),
                              minimumSize: Size(80, 56),
                            ),
                            child: Text(
                              'Submit',
                              style: TextStyle(color: AppColors.buttonText),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isAnswerCorrect != null)
            Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isAnswerCorrect!
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _isAnswerCorrect! ? AppColors.success : AppColors.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAnswerCorrect! ? Icons.check_circle : Icons.error,
                    color:
                        _isAnswerCorrect! ? AppColors.success : AppColors.error,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isAnswerCorrect!
                          ? 'Correct!'
                          : 'Incorrect. The correct answer is: ${widget.questions[currentQuestionIndex].correctAnswer}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (selectedAnswer != null &&
              (widget.quiz.mode == QuizMode.multipleChoice ||
                  widget.quiz.mode == QuizMode.trueFalse))
            ExplanationSection(
              explanation: widget.questions[currentQuestionIndex].explanation,
            ),
        ],
      );
    } else if (widget.quiz.mode == QuizMode.trueFalse) {
      return Column(
        children: [
          Text(
            widget.questions[currentQuestionIndex].question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['True', 'False'].map((option) {
              final isSelected = selectedAnswer == option;
              final isCorrect =
                  widget.questions[currentQuestionIndex].correctAnswer ==
                      option;
              final hasAnswered = selectedAnswer != null;

              Color getButtonColor() {
                if (!hasAnswered) return Colors.white;
                if (isSelected && isCorrect)
                  return AppColors.success.withOpacity(0.1);
                if (isSelected && !isCorrect)
                  return AppColors.error.withOpacity(0.1);
                if (isCorrect) return AppColors.success.withOpacity(0.1);
                return Colors.white;
              }

              Color getBorderColor() {
                if (!hasAnswered) return AppColors.cardBorder;
                if (isSelected && isCorrect) return AppColors.success;
                if (isSelected && !isCorrect) return AppColors.error;
                if (isCorrect) return AppColors.success;
                return AppColors.cardBorder;
              }

              Color getTextColor() {
                if (!hasAnswered) return AppColors.primary;
                if (isSelected && isCorrect) return AppColors.success;
                if (isSelected && !isCorrect) return AppColors.error;
                if (isCorrect) return AppColors.success;
                return AppColors.primary;
              }

              return Container(
                decoration: BoxDecoration(
                  color: getButtonColor(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: getBorderColor(),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: hasAnswered ? null : () => _selectAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getButtonColor(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasAnswered &&
                          ((isSelected && isCorrect) ||
                              (!isSelected && isCorrect)))
                        Icon(Icons.check_circle,
                            color: AppColors.success, size: 20),
                      if (hasAnswered && isSelected && !isCorrect)
                        Icon(Icons.cancel, color: AppColors.error, size: 20),
                      if (hasAnswered) SizedBox(width: 8),
                      Text(
                        option,
                        style: TextStyle(
                          color: getTextColor(),
                          fontSize: 18,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedAnswer != null &&
              (widget.quiz.mode == QuizMode.multipleChoice ||
                  widget.quiz.mode == QuizMode.trueFalse))
            ExplanationSection(
              explanation: widget.questions[currentQuestionIndex].explanation,
            ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.questions[currentQuestionIndex].question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          Container(
            height: 300,
            child: ListView.separated(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemCount: widget.questions[currentQuestionIndex].options.length,
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option =
                    widget.questions[currentQuestionIndex].options[index];
                final isSelected = selectedAnswer == option;
                final isCorrect =
                    widget.questions[currentQuestionIndex].correctAnswer ==
                        option;
                final hasAnswered = selectedAnswer != null;

                Color getOptionColor() {
                  if (!hasAnswered) return AppColors.background;
                  if (isSelected && isCorrect)
                    return AppColors.success.withOpacity(0.1);
                  if (isSelected && !isCorrect)
                    return AppColors.error.withOpacity(0.1);
                  if (isCorrect) return AppColors.success.withOpacity(0.1);
                  return AppColors.background;
                }

                return GestureDetector(
                  onTap: hasAnswered ? null : () => _selectAnswer(option),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: getOptionColor(),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.background,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (selectedAnswer != null &&
              (widget.quiz.mode == QuizMode.multipleChoice ||
                  widget.quiz.mode == QuizMode.trueFalse))
            ExplanationSection(
              explanation: widget.questions[currentQuestionIndex].explanation,
            ),
        ],
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: widget.quiz.mode == QuizMode.openEnded
          ? FloatingActionButton(
              onPressed: _toggleListening,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
              backgroundColor: _isListening ? AppColors.primary : Colors.grey,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => _showQuitDialog(context),
                    ),
                    QuizTimer(
                      minutes: widget.quiz.timerMinutes,
                      onTimeUp: _showTimeUpDialog,
                    ),
                    Text(
                      '${currentQuestionIndex + 1}/${widget.questions.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                _buildQuestionContent(),
                SizedBox(height: 24),
                if (widget.quiz.mode != QuizMode.trueFalse)
                  HintSection(
                    currentHint: currentHint,
                    isLoadingHint: isLoadingHint,
                    onGetHint: _getHint,
                  ),
                ElevatedButton(
                  onPressed:
                      (selectedAnswer != null || _isAnswerCorrect != null)
                          ? (currentQuestionIndex == widget.questions.length - 1
                              ? _finishQuiz
                              : _nextQuestion)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: Size(double.infinity, 56),
                  ),
                  child: Text(
                    currentQuestionIndex == widget.questions.length - 1
                        ? 'Finish Quiz'
                        : 'Next Question',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
