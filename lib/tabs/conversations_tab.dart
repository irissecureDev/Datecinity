import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/api/conversations_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/progress_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/chat_screen.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsTab extends StatefulWidget {
  const ConversationsTab({super.key});

  @override
  ConversationsTabState createState() => ConversationsTabState();
}

class ConversationsTabState extends State<ConversationsTab> {
  final ConversationsApi _conversationsApi = ConversationsApi();
  late AppLocalizations _i18n;
  late ProgressDialog _pr;
  final Map<String, int> _userAgeCache = {};

  /// Get correct display name from conversation document
  String _getDisplayName(Map<String, dynamic> conversation) {
    try {
      String fullName = conversation[USER_FULLNAME] ?? "";
      if (fullName.isEmpty) return "User";

      // Take only first name (first word)
      List<String> nameParts = fullName.trim().split(" ");
      return nameParts.isNotEmpty ? nameParts[0] : "User";
    } catch (e) {
      debugPrint("Error getting display name: $e");
      return "User";
    }
  }

  /// Formater le timestamp de manière cohérente
  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        dateTime = DateTime.now();
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return "Now";
      if (difference.inMinutes < 60) return "${difference.inMinutes}m";
      if (difference.inHours < 24) return "${difference.inHours}h";
      if (difference.inDays < 7) return "${difference.inDays}d";
      return timeago.format(dateTime, locale: 'en');
    } catch (e) {
      debugPrint("Error formatting timestamp: $e");
      return "";
    }
  }

  /// Get user age from cache or Firestore
  Future<int?> _getUserAge(String userId) async {
    if (userId.isEmpty) return null;

    if (_userAgeCache.containsKey(userId)) {
      return _userAgeCache[userId];
    }

    try {
      final userDoc = await UserModel().getUser(userId);
      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      final birthYear = data[USER_BIRTH_YEAR] ?? 0;
      final birthMonth = data[USER_BIRTH_MONTH] ?? 0;
      final birthDay = data[USER_BIRTH_DAY] ?? 0;

      if (birthYear == 0 || birthMonth == 0 || birthDay == 0) {
        return null;
      }

      final birthDate = DateTime(birthYear, birthMonth, birthDay);
      final age = UserModel().calculateUserAge(birthDate);

      _userAgeCache[userId] = age;
      return age;
    } catch (e) {
      debugPrint('Error getting user age: $e');
      return null;
    }
  }

  /// Build a modern conversation item
  Widget _buildConversationItem(
    DocumentSnapshot<Map<String, dynamic>> conversation, {
    required bool showDivider,
  }) {
    final data = conversation.data()!;
    final isUnread = !(data[MESSAGE_READ] ?? true);
    final displayName = _getDisplayName(data);
    final lastMessage = data[LAST_MESSAGE] ?? "";
    final messageType = data[MESSAGE_TYPE] ?? "text";
    final timestamp = _formatTimestamp(data[TIMESTAMP]);
    final userPhoto = data[USER_PROFILE_PHOTO] ?? "";
    final userId = data[USER_ID] ?? "";

    final previewText = messageType == 'image'
        ? _i18n.translate("photo")
        : (lastMessage.isEmpty ? "..." : lastMessage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openChat(conversation),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: userPhoto.isNotEmpty
                          ? Image.network(
                              userPhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFE6E6EE),
                                  child: const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color(0xFF9B9BAA),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFFE6E6EE),
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: Color(0xFF9B9BAA),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FutureBuilder<int?>(
                                future: _getUserAge(userId),
                                builder: (context, snapshot) {
                                  final age = snapshot.data;
                                  final title = age != null
                                      ? "$displayName, $age"
                                      : displayName;

                                  return Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF232332),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (timestamp.isNotEmpty)
                              Row(
                                children: [
                                  Text(
                                    timestamp,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8A8A98),
                                    ),
                                  ),
                                  if (isUnread) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.35),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          previewText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.1,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7A7A89),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFECECF2),
                indent: 98,
                endIndent: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Open a conversation
  Future<void> _openChat(
    DocumentSnapshot<Map<String, dynamic>> conversation,
  ) async {
    try {
      final data = conversation.data()!;

      // Show progress dialog
      _pr.show(_i18n.translate("loading"));

      // Mark as read
      if (!(data[MESSAGE_READ] ?? true)) {
        await conversation.reference.update({MESSAGE_READ: true});
      }

      // Get updated user information
      final userDoc = await UserModel().getUser(data[USER_ID]);

      if (!userDoc.exists) {
        _pr.hide();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_i18n.translate("user_not_found")),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final User user = User.fromDocument(userDoc.data()!);

      // Hide progress dialog
      _pr.hide();

      // Navigate to chat screen
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => ChatScreen(user: user)));
      }
    } catch (e) {
      _pr.hide();
      debugPrint("Error opening chat: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_i18n.translate("error_opening_chat")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context);

    return Container(
      color: const Color(0xFFF2EEFF),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: SvgIcon(
                        "assets/icons/message_icon.svg",
                        width: 25,
                        height: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _i18n.translate("chats"),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF232332),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFECECF2)),

          // Conversations list
          Expanded(
            child: Container(
              color: const Color(0xFFF2EEFF),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _conversationsApi.getConversations(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _i18n.translate("loading"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _i18n.translate("no_conversation"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start matching to begin conversations!",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs.toList();

                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _i18n.translate("no_conversation"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start matching to begin conversations!",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 6),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      return _buildConversationItem(
                        docs[index],
                        showDivider: index != docs.length - 1,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
