import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubsohbet/app_data.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<String?>(
      valueListenable: kActiveChat,
      builder: (context, activeChat, _) {
        if (activeChat != null) {
          return _ChatView(
            friendId: activeChat,
            messageController: _messageController,
          );
        }

        return Stack(
          children: [
            const _AtlasBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mesajlar',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 30,
                            letterSpacing: 1.2,
                            color: _atlasInk,
                          ),
                        ),
                        const Spacer(),
                        const _AtlasChip(
                          label: 'Gelen kutusu',
                          icon: Icons.inbox_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sohbetlerin burada listelenir.',
                      style: GoogleFonts.spaceGrotesk(
                        textStyle: textTheme.bodyMedium,
                        color: withOpacity(_atlasInk, 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _InboxList(user: user),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const _EmptyMessagesState();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('friends')
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyMessagesState();
        }
        final friends = docs
            .map(
              (doc) => _FriendEntry(
                id: doc.id,
                name: (doc.data()['name'] as String?) ?? 'Kullanici',
              ),
            )
            .toList();

        return ListView.separated(
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _ChatListTile(friend: friend, userId: user!.uid);
          },
        );
      },
    );
  }
}

class _FriendEntry {
  const _FriendEntry({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.friend,
    required this.userId,
  });

  final _FriendEntry friend;
  final String userId;

  String _chatId() {
    final ids = [userId, friend.id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chatId = _chatId();

    return InkWell(
      onTap: () {
        kActiveChat.value = friend.id;
        kActiveChatName.value = friend.name;
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _atlasCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
          boxShadow: [
            BoxShadow(
              color: _atlasShadow,
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: withOpacity(_atlasTeal, 0.15),
              ),
              child: const Icon(
                Icons.chat_bubble,
                color: _atlasTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(friend.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final profileName =
                          snapshot.data?.data()?['name'] as String?;
                      final displayName =
                          (profileName != null && profileName.trim().isNotEmpty)
                              ? profileName.trim()
                              : friend.name;
                      return Text(
                        displayName,
                        style: GoogleFonts.spaceGrotesk(
                          textStyle: textTheme.bodyLarge,
                          fontWeight: FontWeight.w700,
                          color: _atlasInk,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();
                      final lastMessage =
                          (data?['lastMessage'] as String?) ?? 'Sohbet';
                      return Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          textStyle: textTheme.bodyMedium,
                          color: withOpacity(_atlasInk, 0.6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({
    required this.friendId,
    required this.messageController,
  });

  final String friendId;
  final TextEditingController messageController;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _chatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _sendMessage(String friendId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final text = widget.messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    widget.messageController.clear();

    final chatId = _chatId(user.uid, friendId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await chatRef.set(
      {
        'participants': [user.uid, friendId],
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': user.uid,
      },
      SetOptions(merge: true),
    );
    await messageRef.set({
      'senderId': user.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = _auth.currentUser;
    final chatId = user == null ? null : _chatId(user.uid, widget.friendId);

    return Stack(
      children: [
        const _AtlasBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        kActiveChat.value = null;
                        kActiveChatName.value = null;
                      },
                      icon: const Icon(Icons.arrow_back, color: _atlasInk),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: user == null
                            ? null
                            : _firestore
                                .collection('users')
                                .doc(widget.friendId)
                                .snapshots(),
                        builder: (context, snapshot) {
                          final profileName =
                              snapshot.data?.data()?['name'] as String?;
                          final fallbackName = kActiveChatName.value;
                          final name =
                              (profileName != null &&
                                      profileName.trim().isNotEmpty)
                                  ? profileName.trim()
                                  : (fallbackName != null &&
                                          fallbackName.trim().isNotEmpty)
                                      ? fallbackName.trim()
                                      : 'Sohbet';
                          return Text(
                            name,
                            style: GoogleFonts.spaceGrotesk(
                              textStyle: textTheme.titleLarge,
                              fontWeight: FontWeight.w700,
                              color: _atlasInk,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _atlasCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: _atlasShadow,
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: user == null || chatId == null
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Mesajlasma burada baslayacak.',
                              style: GoogleFonts.spaceGrotesk(
                                textStyle: textTheme.bodyMedium,
                                color: withOpacity(_atlasInk, 0.7),
                              ),
                            ),
                          )
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _firestore
                                .collection('chats')
                                .doc(chatId)
                                .collection('messages')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Mesajlasma burada baslayacak.',
                                    style: GoogleFonts.spaceGrotesk(
                                      textStyle: textTheme.bodyMedium,
                                      color: withOpacity(_atlasInk, 0.7),
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                reverse: true,
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final text =
                                      (data['text'] as String?) ?? '';
                                  final senderId =
                                      data['senderId'] as String?;
                                  final isMe = senderId == user.uid;
                                  return _MessageBubble(
                                    text: text,
                                    isMe: isMe,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.messageController,
                        decoration: InputDecoration(
                          hintText: 'Mesaj yaz...',
                          hintStyle:
                              TextStyle(color: withOpacity(_atlasInk, 0.45)),
                          filled: true,
                          fillColor: _atlasCard,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                BorderSide(color: withOpacity(_atlasTeal, 0.4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                BorderSide(color: withOpacity(_atlasTeal, 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: _atlasTeal, width: 1.4),
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(widget.friendId),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => _sendMessage(widget.friendId),
                      style: FilledButton.styleFrom(
                        backgroundColor: _atlasAmber,
                        padding: const EdgeInsets.all(14),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.send, color: _atlasInk),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.isMe,
  });

  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
        isMe ? withOpacity(_atlasAmber, 0.25) : withOpacity(kMist, 0.9);
    final textColor = _atlasInk;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: withOpacity(_atlasTeal, isMe ? 0.25 : 0.18),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            textStyle: Theme.of(context).textTheme.bodyMedium,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _atlasCard,
            border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
            boxShadow: [
              BoxShadow(
                color: _atlasShadow,
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: withOpacity(_atlasTeal, 0.15),
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: _atlasTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mesajlasma henuz baslamadi',
                      style: GoogleFonts.spaceGrotesk(
                        textStyle: textTheme.bodyLarge,
                        fontWeight: FontWeight.w700,
                        color: _atlasInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Mesajlasmak icin arkadas ekle. Eslesmelerin burada gorunur.',
                style: GoogleFonts.spaceGrotesk(
                  textStyle: textTheme.bodyMedium,
                  color: withOpacity(_atlasInk, 0.7),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    kNavIndex.value = 3;
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _atlasAmber,
                    foregroundColor: _atlasInk,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Arkadas ekle'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: const [
            _AtlasInfoChip(
              icon: Icons.lightbulb_outline,
              label: 'Hizli eslesme: 14 sn',
            ),
            _AtlasInfoChip(
              icon: Icons.lock_outline,
              label: 'Gizli ve anonim',
            ),
          ],
        ),
      ],
    );
  }
}

class _AtlasBackground extends StatelessWidget {
  const _AtlasBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F7F7), Color(0xFFEFEFEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _AtlasChip extends StatelessWidget {
  const _AtlasChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _atlasTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              color: _atlasInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _AtlasInfoChip extends StatelessWidget {
  const _AtlasInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: withOpacity(_atlasTeal, 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: withOpacity(_atlasInk, 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              color: withOpacity(_atlasInk, 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
