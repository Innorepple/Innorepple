import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/gemini_service.dart';
import '../../services/localization_service.dart';

class MedBotScreen extends StatefulWidget {
  const MedBotScreen({super.key});

  @override
  State<MedBotScreen> createState() => _MedBotScreenState();
}

class _MedBotScreenState extends State<MedBotScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];
  // bool _loading = false; // Removed unused field
  Uint8List? _pendingImage;
  String? _pendingImageName;
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;
  bool _showTypingIndicator = false;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gemini = context.read<GeminiService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Bubble backgrounds and text colors with proper contrast per theme
    final incomingBg = isDark ? theme.colorScheme.surface : Colors.white;
    final outgoingBg = isDark ? theme.colorScheme.primary.withOpacity(0.15) : Colors.teal.shade100;
    final incomingTextColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    final outgoingTextColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    return Scaffold(
      appBar: AppBar(title: const Text('Med Bot')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.smart_toy, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          LocalizationService.t('hello_medical_assistant'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocalizationService.t('ask_health_question'),
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_showTypingIndicator ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length && _showTypingIndicator) {
                        // Enhanced typing indicator
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? theme.colorScheme.surface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.smart_toy, color: Colors.teal, size: 16),
                                const SizedBox(width: 8),
                                AnimatedBuilder(
                                  animation: _typingAnimation,
                                  builder: (context, child) {
                                    return Row(
                                      children: List.generate(3, (index) {
                                        final delay = index * 0.3;
                                        final opacity = ((_typingAnimation.value - delay) % 1.0).clamp(0.0, 1.0);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2),
                                          child: Opacity(
                                            opacity: (opacity * 2 - 1).abs(),
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.teal,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text('Med Bot is typing...', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final m = _messages[i];
                      return Align(
                        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: m.mine ? outgoingBg : incomingBg,
                            borderRadius: BorderRadius.circular(12),
boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.hasImage)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image, size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text('Image attached', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              Text(
                                m.text,
                                style: TextStyle(
                                  color: m.mine ? outgoingTextColor : incomingTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (!gemini.isConfigured)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gemini API key not configured. Medical bot functionality is disabled.',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (_pendingImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingImageName ?? 'Image selected',
                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                    onPressed: () {
                      setState(() {
                        _pendingImage = null;
                        _pendingImageName = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.blue, size: 18),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Voice',
              onPressed: _showTypingIndicator ? null : _startVoice,
                  icon: const Icon(Icons.mic),
                ),
                IconButton(
                  tooltip: 'Attach image',
                  onPressed: (_showTypingIndicator || !gemini.isConfigured) ? null : () async {
                    try {
                      final picker = ImagePicker();
                      final xfile = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1600,
                        imageQuality: 85,
                      );
                      if (xfile != null) {
                        final imageBytes = await xfile.readAsBytes();
                        if (mounted) {
                          setState(() {
                            _pendingImage = imageBytes;
                            _pendingImageName = xfile.name;
                          });
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image attached successfully!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to load image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    Icons.image,
                    color: (_showTypingIndicator || !gemini.isConfigured) ? Colors.grey : null,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_showTypingIndicator && gemini.isConfigured,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything health-related...',
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: (_showTypingIndicator || !gemini.isConfigured) ? null : _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color: (_showTypingIndicator || !gemini.isConfigured) ? Colors.grey : null,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final gemini = context.read<GeminiService>();
    if (!gemini.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API key not configured. Please restart the app with proper configuration.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Clear input and add user message
    _controller.clear();
    final hasImage = _pendingImage != null;
    setState(() {
      _messages.add(_Msg(text, true, hasImage: hasImage));
      _showTypingIndicator = true;
    });

    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      String reply;
      if (_pendingImage != null) {
        reply = await gemini.askWithImage(
          prompt: text,
          imageBytes: _pendingImage!,
        );
      } else {
        reply = await gemini.askText(text);
      }
      
      if (mounted) {
        setState(() {
          _messages.add(_Msg(reply, false));
          _showTypingIndicator = false;
          _pendingImage = null;
          _pendingImageName = null;
        });
        
        // Auto scroll to bottom after response
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Msg('Sorry, I encountered an error: $e', false));
          _showTypingIndicator = false;
          _pendingImage = null;
          _pendingImageName = null;
        });
      }
    }
  }

  Future<void> _startVoice() async {
    if (!context.read<GeminiService>().isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input requires API key configuration.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      final stt = speech.SpeechToText();
      final available = await stt.initialize(
        onError: (error) {
          print('Speech to text error: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: ${error.errorMsg}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onStatus: (status) {
          print('Speech to text status: $status');
          if (status == 'listening' && mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎤 Listening... Speak now!'),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (status == 'done' && mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice input completed'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
      );
      
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Check for microphone permission
      final hasPermission = await stt.hasPermission;
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required for voice input.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Get available locales and use the first one
      final locales = await stt.locales();
      final selectedLocale = locales.isNotEmpty ? locales.first.localeId : 'en_US';
      
      await stt.listen(
        onResult: (result) {
          if (mounted && result.recognizedWords.isNotEmpty) {
            _controller.text = result.recognizedWords;
            setState(() {});
            
            // If the result is final, stop listening
            if (result.finalResult) {
              stt.stop();
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: selectedLocale,
        onSoundLevelChange: (level) {
          // Optional: Show sound level feedback
        },
      );
      
    } catch (e) {
      print('Speech to text exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _Msg {
  final String text;
  final bool mine;
  final bool hasImage;
  
  _Msg(this.text, this.mine, {this.hasImage = false});
}
