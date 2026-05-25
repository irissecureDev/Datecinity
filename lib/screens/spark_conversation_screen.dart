import 'package:flutter/material.dart';
import 'package:datecinity/widgets/spark_theme.dart';
import 'package:datecinity/models/spark.dart';
import 'package:datecinity/services/spark_service.dart';
import 'package:datecinity/screens/chat_screen.dart';

/// Écran de démarrage de conversation - Suggestions de messages
class SparkConversationScreen extends StatefulWidget {
  final Spark spark;

  const SparkConversationScreen({super.key, required this.spark});

  @override
  State<SparkConversationScreen> createState() =>
      _SparkConversationScreenState();
}

class _SparkConversationScreenState extends State<SparkConversationScreen> {
  final SparkService _sparkService = SparkService();
  final TextEditingController _messageController = TextEditingController();
  late List<String> _conversationStarters;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _conversationStarters = _sparkService.generateConversationStarters(
      widget.spark,
    );
  }

  void _selectStarter(String message) {
    // Ouvrir l'écran de chat avec le message pré-rempli
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          user: widget.spark.user,
          // Le message sera envoyé automatiquement ou pré-rempli
        ),
      ),
    );
  }

  void _sendCustomMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(user: widget.spark.user),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.spark.user.userFullname.split(' ')[0];

    return Scaffold(
      body: SparkBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header avec bouton retour
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: SparkTheme.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Logo
                      const SparkLogo(size: 60),

                      const SizedBox(height: 24),

                      // Titre
                      const Text(
                        'Start the\nconversation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: SparkTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Suggestions de messages
                      ..._conversationStarters.map(
                        (starter) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildMessageSuggestion(starter),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bouton "Send Your Own"
                      if (!_showCustomInput)
                        GestureDetector(
                          onTap: () => setState(() => _showCustomInput = true),
                          child: SparkCard(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: SparkTheme.cardBackgroundLight,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: SparkTheme.textSecondary,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Send Your Own',
                                  style: TextStyle(
                                    color: SparkTheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Input personnalisé
                      if (_showCustomInput)
                        Column(
                          children: [
                            SparkCard(
                              padding: const EdgeInsets.all(4),
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(
                                  color: SparkTheme.textPrimary,
                                ),
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText:
                                      'Write your message to $firstName...',
                                  hintStyle: const TextStyle(
                                    color: SparkTheme.textMuted,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SparkGradientButton(
                              text: 'Send Message',
                              onPressed: _sendCustomMessage,
                            ),
                          ],
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageSuggestion(String message) {
    return GestureDetector(
      onTap: () => _selectStarter(message),
      child: SparkCard(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: const TextStyle(
            color: SparkTheme.textPrimary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
