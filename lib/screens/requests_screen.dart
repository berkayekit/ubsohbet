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

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

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
                      'Istekler',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 30,
                        letterSpacing: 1.2,
                        color: _atlasInk,
                      ),
                    ),
                    const Spacer(),
                    _RequestCountBadge(user: user),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Gelen arkadaslik isteklerini buradan yonet.',
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodyMedium,
                    color: withOpacity(_atlasInk, 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _RequestsList(user: user),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestCountBadge extends StatelessWidget {
  const _RequestCountBadge({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('recipientId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _AtlasChip(
          label: '$count yeni',
          icon: Icons.notifications_outlined,
        );
      },
    );
  }
}

class _FriendRequestEntry {
  const _FriendRequestEntry({
    required this.requestId,
    required this.senderId,
    required this.name,
    required this.roomId,
  });

  final String requestId;
  final String senderId;
  final String name;
  final String? roomId;
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.user});

  final User? user;

  Future<void> _acceptRequest(
    BuildContext context,
    User user,
    _FriendRequestEntry request,
  ) async {
    final firestore = FirebaseFirestore.instance;
    String recipientName = 'Kullanici';
    try {
      final profileSnap = await firestore.collection('users').doc(user.uid).get();
      final data = profileSnap.data();
      final name = data?['name'];
      if (name is String && name.trim().isNotEmpty) {
        recipientName = name.trim();
      }
    } catch (_) {
      // Ignore profile lookup failures.
    }

    final batch = firestore.batch();
    final senderFriendRef = firestore
        .collection('users')
        .doc(request.senderId)
        .collection('friends')
        .doc(user.uid);
    final recipientFriendRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .doc(request.senderId);
    final requestRef = firestore
        .collection('friend_requests')
        .doc(request.requestId);

    batch.set(
      recipientFriendRef,
      {
        'friendId': request.senderId,
        'name': request.name,
        'addedAt': FieldValue.serverTimestamp(),
        'roomId': request.roomId,
      },
      SetOptions(merge: true),
    );
    batch.set(
      senderFriendRef,
      {
        'friendId': user.uid,
        'name': recipientName,
        'addedAt': FieldValue.serverTimestamp(),
        'roomId': request.roomId,
      },
      SetOptions(merge: true),
    );
    batch.delete(requestRef);
    try {
      await batch.commit();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arkadas eklendi: ${request.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arkadaslik istegi kabul edilemedi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    User user,
    _FriendRequestEntry request,
  ) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(request.requestId)
        .delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Istek reddedildi: ${request.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) {
      return const _EmptyRequestsState();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('recipientId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyRequestsState();
        }
        final requests = docs
            .map(
              (doc) => _FriendRequestEntry(
                requestId: doc.id,
                senderId: (doc.data()['senderId'] as String?) ?? doc.id,
                name: (doc.data()['senderName'] as String?) ?? 'Kullanici',
                roomId: doc.data()['roomId'] as String?,
              ),
            )
            .toList();

        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = requests[index];
            return Ink(
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
                          Icons.person_add_alt_1,
                          color: _atlasTeal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          request.name,
                          style: GoogleFonts.spaceGrotesk(
                            textStyle: Theme.of(context).textTheme.bodyLarge,
                            fontWeight: FontWeight.w700,
                            color: _atlasInk,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: withOpacity(_atlasAmber, 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: withOpacity(_atlasAmber, 0.4),
                          ),
                        ),
                        child: Text(
                          'Istek',
                          style: GoogleFonts.spaceGrotesk(
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                            color: _atlasInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              _acceptRequest(context, currentUser, request),
                          style: FilledButton.styleFrom(
                            backgroundColor: _atlasAmber,
                            foregroundColor: _atlasInk,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Kabul et'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _rejectRequest(context, currentUser, request),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: withOpacity(_atlasTeal, 0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Reddet',
                            style: GoogleFonts.spaceGrotesk(
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                              color: _atlasInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyRequestsState extends StatelessWidget {
  const _EmptyRequestsState();

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
                      Icons.inbox_outlined,
                      color: _atlasTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Henuz istek yok',
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
                'Arkadaslik isteklerin burada gorunecek.',
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.explore),
                  label: const Text('Yeni kisiler bul'),
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
              label: 'Onayla veya reddet',
            ),
            _AtlasInfoChip(
              icon: Icons.chat_bubble_outline,
              label: 'Sohbet icin kabul et',
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
