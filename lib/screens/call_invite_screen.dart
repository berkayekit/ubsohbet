import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/screens/voice_room_screen.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasShadow = Color(0x1A121214);

class CallInviteScreen extends StatefulWidget {
  const CallInviteScreen.incoming({
    super.key,
    required this.roomId,
    required this.callerId,
    required this.calleeId,
    required this.partnerName,
    this.fromFriendsCall = false,
  }) : isIncoming = true;

  const CallInviteScreen.outgoing({
    super.key,
    required this.roomId,
    required this.callerId,
    required this.calleeId,
    required this.partnerName,
    this.fromFriendsCall = false,
  }) : isIncoming = false;

  final String roomId;
  final String callerId;
  final String calleeId;
  final String partnerName;
  final bool isIncoming;
  final bool fromFriendsCall;

  @override
  State<CallInviteScreen> createState() => _CallInviteScreenState();
}

class _CallInviteScreenState extends State<CallInviteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _timeoutTimer;
  int _remainingSeconds = 30;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _listenStatus();
    _startTimeout();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _handled) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _rejectCall();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _listenStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('call_requests')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        if (!_handled && mounted) {
          Navigator.of(context).maybePop();
        }
        return;
      }
      final status = data['status'] as String? ?? 'pending';
      if (status == 'accepted') {
        if (!_handled) {
          _handled = true;
          _openCall();
        }
        return;
      }
      if (status == 'rejected' || status == 'canceled') {
        if (!_handled && mounted) {
          _handled = true;
          _timeoutTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arama reddedildi.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).maybePop();
        }
        return;
      }
    }, onError: (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama bilgisi alinamadi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Future<void> _updateCallStatus(String status) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final callerRef = firestore
        .collection('users')
        .doc(widget.callerId)
        .collection('call_requests')
        .doc(widget.roomId);
    final calleeRef = firestore
        .collection('users')
        .doc(widget.calleeId)
        .collection('call_requests')
        .doc(widget.roomId);
    batch.set(callerRef, {'status': status}, SetOptions(merge: true));
    batch.set(calleeRef, {'status': status}, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> _acceptCall() async {
    try {
      await _updateCallStatus('accepted');
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({'status': 'active'}, SetOptions(merge: true));
      if (!mounted) return;
      _handled = true;
      _timeoutTimer?.cancel();
      _openCall();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama kabul edilemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectCall() async {
    try {
      await _updateCallStatus('rejected');
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({'status': 'rejected'}, SetOptions(merge: true));
    } catch (_) {
      // Ignore failures here.
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _openCall() {
    if (!mounted) return;
    final partnerKey = widget.calleeId == _auth.currentUser?.uid
        ? widget.callerId
        : widget.calleeId;
    final city = City(
      name: widget.partnerName,
      matchKey: partnerKey,
      tagline: '',
      onlineCount: 0,
      accent: kSun,
    );
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallSessionScreen(
          city: city,
          roomId: widget.roomId,
          titleOverride: widget.partnerName,
          forcedPartner: widget.partnerName,
          offererId: widget.callerId,
          fromFriendsCall: widget.fromFriendsCall,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncoming = widget.isIncoming;
    return Scaffold(
      body: Stack(
        children: [
          const SimpleBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _rejectCall,
                        icon: const Icon(Icons.arrow_back, color: _atlasInk),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Arama',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 30,
                          letterSpacing: 1.2,
                          color: _atlasInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: withOpacity(_atlasTeal, 0.15),
                      border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: _atlasShadow,
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.person, color: _atlasTeal, size: 56),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.partnerName,
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.headlineSmall,
                      fontWeight: FontWeight.w700,
                      color: _atlasInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isIncoming
                        ? 'Gelen arama'
                        : 'Karsi tarafin onayi bekleniyor',
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyMedium,
                      color: withOpacity(_atlasInk, 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_remainingSeconds sn icinde yanit verilmeli',
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyMedium,
                      color: withOpacity(_atlasInk, 0.6),
                    ),
                  ),
                  const Spacer(),
                  if (isIncoming)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _rejectCall,
                            style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: withOpacity(_atlasTeal, 0.45)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Reddet'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _acceptCall,
                            style: FilledButton.styleFrom(
                              backgroundColor: _atlasAmber,
                              foregroundColor: _atlasInk,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Kabul et'),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _rejectCall,
                        style: OutlinedButton.styleFrom(
                          side:
                              BorderSide(color: withOpacity(_atlasTeal, 0.45)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Vazgec'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
