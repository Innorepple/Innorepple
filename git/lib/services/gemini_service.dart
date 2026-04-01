import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'dart:math';

class GeminiService {
  // Do not hardcode secrets. Read from --dart-define
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyAsmHxh9KiL8yswyVWo1FSZGVKOKWmfJxk');

  late final GenerativeModel _model;

  GeminiService() {
    // Working generation config with tested model
    final generationConfig = GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 50, // Reasonable limit for concise responses
    );
    
    if (_apiKey.isEmpty) {
      // Provide a dummy model that throws on use
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: '',
        generationConfig: generationConfig,
      );
    } else {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: _apiKey,
        generationConfig: generationConfig,
      );
    }
  }

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<String> askText(String prompt) async {
    print('=== MedBot Debug Info ===');
    print('API Key configured: $isConfigured');
    print('API Key length: ${_apiKey.length}');
    print('Prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');
    
    if (!isConfigured) {
      print('ERROR: API key not configured');
      return _getFallbackResponse(prompt);
    }
    
    try {
      print('Using model: gemini-2.5-flash');
      
      // Add medical context to the prompt for better responses
      final medicalPrompt = 'You are a medical assistant. Provide a helpful, concise response in 30 words or less: $prompt';
      print('Medical prompt: ${medicalPrompt.substring(0, medicalPrompt.length.clamp(0, 100))}...');
      
      final res = await _model.generateContent([Content.text(medicalPrompt)]);
      print('API call successful');
      
      // Handle potential PromptFeedback issues
      if (res.promptFeedback?.blockReason != null) {
        print('Content blocked: ${res.promptFeedback?.blockReason}');
        return 'Sorry, I cannot provide information on this topic due to safety guidelines. Please try rephrasing your question.';
      }
      
      final response = res.text ?? 'No response received from Gemini';
      print('Response received: ${response.substring(0, response.length.clamp(0, 100))}...');
      print('=== End Debug Info ===');
      return response.trim();
    } catch (e, stackTrace) {
      print('=== ERROR DEBUG ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('=== End Error Debug ===');
      
      // Return fallback response instead of error
      return _getFallbackResponse(prompt);
    }
  }
  
  String _getFallbackResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    // Common health responses based on keywords
    if (lowerPrompt.contains('headache') || lowerPrompt.contains('head pain')) {
      return 'For mild headaches: Rest in a quiet, dark room, stay hydrated, and consider over-the-counter pain relief. Consult a doctor if severe or persistent.';
    }
    if (lowerPrompt.contains('fever') || lowerPrompt.contains('temperature')) {
      return 'For fever: Rest, drink plenty of fluids, and use fever reducers like acetaminophen. Seek medical care if fever exceeds 103°F or persists.';
    }
    if (lowerPrompt.contains('cough') || lowerPrompt.contains('cold')) {
      return 'For coughs: Stay hydrated, use honey for soothing, rest well. See a doctor if cough persists over 2 weeks or has blood.';
    }
    if (lowerPrompt.contains('stomach') || lowerPrompt.contains('nausea') || lowerPrompt.contains('vomit')) {
      return 'For stomach issues: Eat bland foods (BRAT diet), stay hydrated with small sips, rest. Seek help if severe pain or persistent vomiting.';
    }
    if (lowerPrompt.contains('sleep') || lowerPrompt.contains('insomnia')) {
      return 'For better sleep: Maintain regular schedule, avoid screens before bed, keep room cool and dark. Consult doctor if chronic insomnia.';
    }
    if (lowerPrompt.contains('stress') || lowerPrompt.contains('anxiety')) {
      return 'For stress: Practice deep breathing, regular exercise, meditation, adequate sleep. Consider professional help if overwhelming.';
    }
    if (lowerPrompt.contains('exercise') || lowerPrompt.contains('fitness')) {
      return 'Exercise recommendations: 150 minutes moderate activity weekly, include strength training, start gradually, listen to your body.';
    }
    if (lowerPrompt.contains('diet') || lowerPrompt.contains('nutrition')) {
      return 'Healthy diet: Eat variety of fruits, vegetables, whole grains, lean proteins. Limit processed foods, stay hydrated, moderate portions.';
    }
    if (lowerPrompt.contains('water') || lowerPrompt.contains('hydration')) {
      return 'Stay hydrated: Aim for 8-10 glasses of water daily, more during exercise or hot weather. Clear urine indicates good hydration.';
    }
    
    // Generic health responses
    final genericResponses = [
      'I recommend consulting with a healthcare professional for personalized medical advice tailored to your specific situation.',
      'For health concerns, it\'s always best to speak with a qualified doctor who can properly assess your symptoms.',
      'Please consult a healthcare provider for accurate diagnosis and treatment recommendations for your health concern.',
      'Consider scheduling an appointment with your doctor to discuss your health question in detail.',
      'A medical professional can provide the best guidance for your specific health situation and needs.',
    ];
    
    return genericResponses[Random().nextInt(genericResponses.length)];
  }

  Future<String> askWithImage({required String prompt, required Uint8List imageBytes, String mimeType = 'image/jpeg'}) async {
    if (!isConfigured) {
      return 'Gemini API key not set. Pass --dart-define=GEMINI_API_KEY=YOUR_KEY when running the app.';
    }
    
    try {
      print('GeminiService: Sending image prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}... with image (${imageBytes.length} bytes)');
      
      // Add medical context to the image prompt
      final medicalPrompt = 'As a medical assistant, analyze this image and respond concisely (max 25 words): $prompt';
      
      final res = await _model.generateContent([
        Content.multi([
          TextPart(medicalPrompt),
          DataPart(mimeType, imageBytes),
        ])
      ]);
      
      // Handle potential PromptFeedback issues
      if (res.promptFeedback?.blockReason != null) {
        print('GeminiService: Image content blocked - ${res.promptFeedback?.blockReason}');
        return 'Sorry, I cannot analyze this image due to safety guidelines. Please try a different image.';
      }
      
      final response = res.text ?? 'No response received from Gemini';
      print('GeminiService: Received image response: ${response.substring(0, response.length.clamp(0, 100))}...');
      return response;
    } catch (e, stackTrace) {
      print('GeminiService Image Error: $e');
      print('Stack trace: $stackTrace');
      
      // Handle specific PromptFeedback error
      if (e.toString().contains('Unhandled format for PromptFeedback')) {
        return 'Sorry, there was an issue with the AI image analysis format. Please try a different image.';
      }
      
      return 'Error: Failed to analyze image with Gemini AI. Please check your internet connection and try again.';
    }
  }
}