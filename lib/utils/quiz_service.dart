import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/quiz_model.dart';

class QuizService {
  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';
  static final String _apiKey = dotenv.env['OPENAI_API_KEY']!;

  static String _buildPrompt(
      String subject, String difficulty, int numberOfQuestions, QuizMode mode) {
    if (mode == QuizMode.trueFalse) {
      return '''
        Generate $numberOfQuestions true/false questions about $subject at $difficulty level.
        Respond with a JSON object in the following format:
        {
          "questions": [
            {
              "question": "Question text here",
              "options": ["True", "False"],
              "correctAnswer": "True or False",
              "explanation": "Brief explanation of why this answer is correct"
            }
          ]
        }
        Ensure the questions are clear, accurate, and appropriate for the specified difficulty level.
      ''';
    } else {
      return '''
        Generate $numberOfQuestions ${mode == QuizMode.openEnded ? 'open-ended' : 'multiple choice'} questions about $subject at $difficulty level.
        Respond with a JSON object in the following format:
        {
          "questions": [
            {
              "question": "Question text here",
              "options": ["Option A", "Option B", "Option C", "Option D"],
              "correctAnswer": "Correct option text",
              "explanation": "Brief explanation of why this answer is correct"
            }
          ]
        }
        Ensure the questions are clear, accurate, and appropriate for the specified difficulty level.
      ''';
    }
  }

  static Future<List<Question>> generateQuestions(Quiz quiz) async {
    try {
      print('Generating questions for subject: ${quiz.subject}');
      print('API Key available: ${_apiKey.isNotEmpty}');

      final response = await http.post(
        Uri.parse(_openaiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful quiz question generator.'
            },
            {
              'role': 'user',
              'content': _buildPrompt(quiz.subject, quiz.difficultyLevel,
                  quiz.numberOfQuestions, quiz.mode)
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
          'max_tokens': 4096,
        }),
      );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String jsonResponse = data['choices'][0]['message']['content'];
        return _parseQuestions(jsonResponse);
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to generate questions: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error stack trace: $stackTrace');
      throw Exception('Error generating questions: $e');
    }
  }

  static List<Question> _parseQuestions(String jsonResponse) {
    try {
      final Map<String, dynamic> parsedResponse = jsonDecode(jsonResponse);
      final List<dynamic> questionData = parsedResponse['questions'];

      return questionData.map((json) {
        if (json['options'] == null) {
          // Handle open-ended questions
          return Question(
            question: json['question'],
            options: const [], // Empty list for open-ended questions
            correctAnswer: json['correctAnswer'],
            explanation: json['explanation'] ?? 'No explanation available.',
          );
        } else {
          // Handle multiple choice and true/false questions
          return Question(
            question: json['question'],
            options: List<String>.from(json['options']),
            correctAnswer: json['correctAnswer'],
            explanation: json['explanation'] ?? 'No explanation available.',
          );
        }
      }).toList();
    } catch (e, stackTrace) {
      print('Parsing error: $e');
      print('Parsing stack trace: $stackTrace');
      print('Raw JSON response: $jsonResponse');
      throw Exception('Error parsing questions: $e');
    }
  }

  static Future<bool> evaluateOpenEndedAnswer(
      String question, String userAnswer, String correctAnswer) async {
    try {
      final response = await http.post(
        Uri.parse(_openaiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {
              'role': 'system',
              'content': '''
                You are an expert answer evaluator with deep knowledge across various subjects.
                Evaluation Guidelines:
                1. Accept common nicknames and alternative names (e.g., "Gunners" for "Arsenal")
                2. Focus on semantic correctness rather than exact wording
                3. Accept partial answers that show correct understanding
                4. Be lenient with spelling, grammar, and capitalization
                5. Consider regional and cultural variations in terminology
                6. Accept both formal and informal correct answers
                7. If the core concept is correct, mark it as correct regardless of additional information
                8. Respond ONLY with "correct" or "incorrect"
                '''
            },
            {
              'role': 'user',
              'content': '''
                Evaluate if this answer demonstrates correct understanding:
                
                Question: "$question"
                Reference Answer: "$correctAnswer"
                Student Answer: "$userAnswer"
                
                Remember:
                - Accept nicknames and alternative names
                - Focus on core concept accuracy
                - Be lenient with formatting and additional information
                - If the main idea is right, it's correct
                
                Respond with only "correct" or "incorrect":
              '''
            }
          ],
          'temperature': 0.0, // Set to 0 for maximum consistency
          'max_tokens': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final evaluation =
            data['choices'][0]['message']['content'].toLowerCase().trim();
        return evaluation == 'correct';
      }
      throw Exception('Failed to evaluate answer');
    } catch (e) {
      throw Exception('Error evaluating answer: $e');
    }
  }

  static Future<String> getHint({
    required String question,
    required String correctAnswer,
    required int hintCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_openaiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {
              'role': 'system',
              'content': '''
                You are a helpful and witty quiz assistant. Follow these rules:
                1. Never reveal the direct answer
                2. Make hints progressively more helpful (this is hint #$hintCount)
                3. Add humor when appropriate to the subject matter
                4. Keep hints concise (1-2 sentences)
                5. Make each hint unique and more revealing than the last
                6. Ensure the hint is directly related to the correct answer
                7. If the subject allows, add a playful or witty tone
              '''
            },
            {
              'role': 'user',
              'content': '''
                Question: "$question"
                Correct Answer: "$correctAnswer"
                Generate hint #$hintCount that guides towards the answer.
                Remember to be progressively more helpful with each hint.
              '''
            }
          ],
          'temperature': 0.7,
          'max_tokens': 100,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      }
      throw Exception('Failed to generate hint');
    } catch (e) {
      throw Exception('Error generating hint: $e');
    }
  }
}
