import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/screens/home_screen.dart';
import 'package:ubsohbet/screens/messages_screen.dart';
import 'package:ubsohbet/screens/requests_screen.dart';
import 'package:ubsohbet/screens/friends_screen.dart';
import 'package:ubsohbet/screens/call_invite_screen.dart';
import 'package:ubsohbet/screens/settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callSub;
  final Set<String> _handledCallEvents = {};

  @override
  void initState() {
    super.initState();
    _listenCallRequests();
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  void _listenCallRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    _callSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('call_requests')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';
        final direction = data['direction'] as String? ?? 'incoming';
        final roomId = data['roomId'] as String? ?? doc.id;
        final callerId = data['callerId'] as String?;
        final calleeId = data['calleeId'] as String?;
        final otherName = data['otherUserName'] as String? ?? 'Kullanici';
        final eventKey = '${doc.id}:$status:$direction';
        if (_handledCallEvents.contains(eventKey)) {
          continue;
        }
        if (status == 'pending' && direction == 'incoming') {
          _handledCallEvents.add(eventKey);
          _openIncomingCallScreen(
            roomId: roomId,
            callerId: callerId,
            calleeId: calleeId,
            callerName: otherName,
            fromFriendsCall: data['fromFriendsCall'] == true,
          );
        }
      }
    }, onError: (error, stackTrace) {
      // Prevent a Firestore permission error from crashing the app.
      debugPrint('Call requests listen error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama istekleri yuklenemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _openIncomingCallScreen({
    required String roomId,
    required String? callerId,
    required String? calleeId,
    required String callerName,
    required bool fromFriendsCall,
  }) {
    if (!mounted || callerId == null || calleeId == null) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CallInviteScreen.incoming(
          roomId: roomId,
          callerId: callerId,
          calleeId: calleeId,
          partnerName: callerName,
          fromFriendsCall: fromFriendsCall,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: kNavIndex,
      builder: (context, currentIndex, _) {
        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: const [
              HomeScreen(),
              MessagesScreen(),
              RequestsScreen(),
              FriendsScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              kNavIndex.value = index;
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: kSun,
            unselectedItemColor: withOpacity(kMidnight, 0.6),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Ana sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Mesajlar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inbox_outlined),
                activeIcon: Icon(Icons.inbox),
                label: 'Istekler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'Arkadaslarim',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Ayarlar',
              ),
            ],
          ),
        );
      },
    );
  }
}
