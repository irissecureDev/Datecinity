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

  /// Obtenir le nom d'affichage correct depuis le document conversation
  String _getDisplayName(Map<String, dynamic> conversation) {
    try {
      String fullName = conversation[USER_FULLNAME] ?? "";
      if (fullName.isEmpty) return "Utilisateur";

      // Prendre le prénom seulement (premier mot)
      List<String> nameParts = fullName.trim().split(" ");
      return nameParts.isNotEmpty ? nameParts[0] : "Utilisateur";
    } catch (e) {
      debugPrint("Error getting display name: $e");
      return "Utilisateur";
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

      if (difference.inDays == 0) {
        // Aujourd'hui - afficher l'heure
        return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      } else if (difference.inDays == 1) {
        // Hier
        return "Hier";
      } else if (difference.inDays < 7) {
        // Cette semaine - afficher le jour
        const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return days[dateTime.weekday - 1];
      } else {
        // Plus d'une semaine - utiliser timeago
        return timeago.format(dateTime, locale: 'fr');
      }
    } catch (e) {
      debugPrint("Error formatting timestamp: $e");
      return "";
    }
  }

  /// Construire un élément de conversation moderne
  Widget _buildConversationItem(
    DocumentSnapshot<Map<String, dynamic>> conversation,
  ) {
    final data = conversation.data()!;
    final isUnread = !(data[MESSAGE_READ] ?? true);
    final displayName = _getDisplayName(data);
    final lastMessage = data[LAST_MESSAGE] ?? "";
    final messageType = data[MESSAGE_TYPE] ?? "text";
    final timestamp = _formatTimestamp(data[TIMESTAMP]);
    final userPhoto = data[USER_PROFILE_PHOTO] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey[200]!,
          width: isUnread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: isUnread ? 8 : 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openChat(conversation),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Photo de profil avec indicateur de statut
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnread
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: isUnread ? 3 : 2,
                        ),
                      ),
                      child: ClipOval(
                        child: userPhoto.isNotEmpty
                            ? Image.network(
                                userPhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey[500],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.grey[500],
                                ),
                              ),
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Contenu de la conversation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne supérieure : Nom et timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          if (timestamp.isNotEmpty)
                            Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isUnread
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[500],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Message preview
                      Row(
                        children: [
                          // Icône pour les images
                          if (messageType == 'image') ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.photo_camera,
                                size: 14,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _i18n.translate("photo"),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isUnread
                                    ? const Color(0xFF2D3748)
                                    : Colors.grey[600],
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: Text(
                                lastMessage.isEmpty ? "..." : lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isUnread
                                      ? const Color(0xFF2D3748)
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge nouveau message et flèche
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnread) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _i18n.translate("new"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isUnread
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ouvrir une conversation
  Future<void> _openChat(
    DocumentSnapshot<Map<String, dynamic>> conversation,
  ) async {
    try {
      final data = conversation.data()!;

      // Afficher le dialogue de progression
      _pr.show(_i18n.translate("loading"));

      // Marquer comme lu
      if (!(data[MESSAGE_READ] ?? true)) {
        await conversation.reference.update({MESSAGE_READ: true});
      }

      // Récupérer les informations utilisateur mises à jour
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

      // Cacher le dialogue de progression
      _pr.hide();

      // Naviguer vers l'écran de chat
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7FAFC), Color(0xFFEDF2F7)],
        ),
      ),
      child: Column(
        children: [
          // En-tête moderne
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SvgIcon(
                    "assets/icons/message_icon.svg",
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _i18n.translate("chats"),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),

          // Liste des conversations
          Expanded(
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
                          "Commencez à matcher pour démarrer des conversations !",
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final conversation = snapshot.data!.docs[index];
                    return _buildConversationItem(conversation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
