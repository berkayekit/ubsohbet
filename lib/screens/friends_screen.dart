import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/screens/call_invite_screen.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final Set<int> _expandedItems = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = _auth.currentUser;
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
                      'Arkadaslarim',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 30,
                        letterSpacing: 1.2,
                        color: _atlasInk,
                      ),
                    ),
                    const Spacer(),
                    _FriendsCountBadge(user: user),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Baglanti listeni buradan yonet.',
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodyMedium,
                    color: withOpacity(_atlasInk, 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _FriendsList(
                    user: user,
                    expandedItems: _expandedItems,
                    onToggle: _toggleExpanded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendsCountBadge extends StatelessWidget {
  const _FriendsCountBadge({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _AtlasChip(
          label: '$count kisi',
          icon: Icons.people_outline,
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

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.user,
    required this.expandedItems,
    required this.onToggle,
  });

  final User? user;
  final Set<int> expandedItems;
  final ValueChanged<int> onToggle;

  Future<bool> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _removeFriend(
    BuildContext context,
    User user,
    _FriendEntry friend,
  ) async {
    final shouldRemove = await _confirmAction(
      context,
      title: 'Arkadasligi sil',
      message: '${friend.name} ile baglanti silinsin mi?',
      confirmLabel: 'Sil',
    );
    if (!shouldRemove) return;
    final firestore = FirebaseFirestore.instance;
    final selfRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .doc(friend.id);
    try {
      await selfRef.delete();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arkadaslik silinemedi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await firestore
          .collection('users')
          .doc(friend.id)
          .collection('friends')
          .doc(user.uid)
          .delete();
    } catch (_) {
      // Ignore failures on the other user's document.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Arkadaslik silindi: ${friend.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _blockFriend(
    BuildContext context,
    User user,
    _FriendEntry friend,
  ) async {
    final shouldBlock = await _confirmAction(
      context,
      title: 'Engelle',
      message: '${friend.name} engellensin mi?',
      confirmLabel: 'Engelle',
    );
    if (!shouldBlock) return;
    final firestore = FirebaseFirestore.instance;
    final selfRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .doc(friend.id);
    final blockRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('blocked')
        .doc(friend.id);
    try {
      final batch = firestore.batch();
      batch.delete(selfRef);
      batch.set(
        blockRef,
        {
          'blockedId': friend.id,
          'name': friend.name,
          'blockedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Engelleme islemi basarisiz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await firestore
          .collection('users')
          .doc(friend.id)
          .collection('friends')
          .doc(user.uid)
          .delete();
    } catch (_) {
      // Ignore failures on the other user's document.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Engellendi: ${friend.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendCallRequest(
    BuildContext context,
    User user,
    _FriendEntry friend,
  ) async {
    final firestore = FirebaseFirestore.instance;
    String callerName = 'Kullanici';
    try {
      final profileSnap =
          await firestore.collection('users').doc(user.uid).get();
      final data = profileSnap.data();
      final name = data?['name'];
      if (name is String && name.trim().isNotEmpty) {
        callerName = name.trim();
      }
    } catch (_) {
      // Ignore profile lookup failures.
    }

    final roomRef = firestore.collection('rooms').doc();
    final roomId = roomRef.id;
    final batch = firestore.batch();
    batch.set(
      roomRef,
      {
        'participants': [user.uid, friend.id],
        'participantNames': {
          user.uid: callerName,
          friend.id: friend.name,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      },
      SetOptions(merge: true),
    );

    final incomingRef = firestore
        .collection('users')
        .doc(friend.id)
        .collection('call_requests')
        .doc(roomId);
    batch.set(
      incomingRef,
      {
        'roomId': roomId,
        'callerId': user.uid,
        'calleeId': friend.id,
        'direction': 'incoming',
        'status': 'pending',
        'otherUserId': user.uid,
        'otherUserName': callerName,
        'fromFriendsCall': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final outgoingRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('call_requests')
        .doc(roomId);
    batch.set(
      outgoingRef,
      {
        'roomId': roomId,
        'callerId': user.uid,
        'calleeId': friend.id,
        'direction': 'outgoing',
        'status': 'pending',
        'otherUserId': friend.id,
        'otherUserName': friend.name,
        'fromFriendsCall': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arama istegi gonderildi: ${friend.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => CallInviteScreen.outgoing(
            roomId: roomId,
            callerId: user.uid,
            calleeId: friend.id,
            partnerName: friend.name,
            fromFriendsCall: true,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama istegi gonderilemedi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) {
      return const _EmptyFriendsState();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyFriendsState();
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
            final isExpanded = expandedItems.contains(index);
            return InkWell(
              onTap: () => onToggle(index),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: withOpacity(_atlasTeal, 0.15),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: _atlasTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.name,
                                style: GoogleFonts.spaceGrotesk(
                                  textStyle:
                                      Theme.of(context).textTheme.bodyLarge,
                                  fontWeight: FontWeight.w700,
                                  color: _atlasInk,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<DatabaseEvent>(
                                stream: FirebaseDatabase.instance
                                    .ref('presence/${friend.id}')
                                    .onValue,
                                builder: (context, snapshot) {
                                  final value = snapshot.data?.snapshot.value;
                                  final online =
                                      value is Map && value['online'] == true;
                                  return Text(
                                    online ? 'Cevrimici' : 'Cevrimdisi',
                                    style: GoogleFonts.spaceGrotesk(
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      fontWeight: FontWeight.w600,
                                      color: online
                                          ? _atlasTeal
                                          : withOpacity(_atlasInk, 0.6),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: withOpacity(_atlasInk, 0.6),
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                kActiveChat.value = friend.id;
                                kNavIndex.value = 1;
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: withOpacity(_atlasTeal, 0.45),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: _atlasInk,
                              ),
                              label: Text(
                                'Mesajlas',
                                style: GoogleFonts.spaceGrotesk(
                                  textStyle:
                                      Theme.of(context).textTheme.bodyMedium,
                                  color: _atlasInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _sendCallRequest(
                                  context,
                                  currentUser,
                                  friend,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: withOpacity(_atlasTeal, 0.45),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.call_outlined,
                                color: _atlasInk,
                              ),
                              label: Text(
                                'Ara',
                                style: GoogleFonts.spaceGrotesk(
                                  textStyle:
                                      Theme.of(context).textTheme.bodyMedium,
                                  color: _atlasInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _removeFriend(
                                context,
                                currentUser,
                                friend,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: withOpacity(_atlasTeal, 0.45),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Arkadasligi sil',
                                style: GoogleFonts.spaceGrotesk(
                                  textStyle:
                                      Theme.of(context).textTheme.bodyMedium,
                                  color: _atlasInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _blockFriend(
                                context,
                                currentUser,
                                friend,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _atlasAmber,
                                foregroundColor: _atlasInk,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Engelle'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _atlasCard,
            borderRadius: BorderRadius.circular(24),
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
                      Icons.group,
                      color: _atlasTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Henuz arkadas eklenmedi',
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
                'Sehirlerden birini secip tanisabilir, burada listeleyebilirsin.',
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
                    kNavIndex.value = 0;
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _atlasAmber,
                    foregroundColor: _atlasInk,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.explore),
                  label: const Text('Sehirlerden ekle'),
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
              icon: Icons.person_add_alt_1,
              label: 'Kisa profil karti',
            ),
            _AtlasInfoChip(
              icon: Icons.shield_outlined,
              label: 'Guvenli baglanti',
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
