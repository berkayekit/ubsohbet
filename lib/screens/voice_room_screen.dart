import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/screens/call_invite_screen.dart';
import 'package:ubsohbet/services/matchmaking_service.dart';
import 'package:ubsohbet/services/presence_service.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class VoiceRoomScreen extends StatefulWidget {
  const VoiceRoomScreen({super.key, required this.city});

  final City city;

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final MatchmakingService _matchmaking = MatchmakingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<MatchResult?>? _matchSub;
  Timer? _retryTimer;
  Timer? _timeoutTimer;
  bool _isConnecting = false;
  bool _hasMatched = false;
  String? _queuedQueueId;
  String? _matchError;
  bool _retryInFlight = false;
  String? _debugStatus;
  int _debugAttempts = 0;


  void _setDebugStatus(String message) {
    if (!mounted) return;
    setState(() {
      _debugStatus = message;
    });
  }

  @override
  void initState() {
    super.initState();
    PresenceService.instance.setActiveCity(widget.city.name);
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    _retryTimer?.cancel();
    _timeoutTimer?.cancel();
    final queueId = _queuedQueueId;
    final userId = _auth.currentUser?.uid;
    if (!_hasMatched && queueId != null) {
      _matchmaking.leaveQueue(queueId);
      PresenceService.instance.clearActiveCity();
    }
    if (!_hasMatched && userId != null) {
      _matchmaking.leaveQueueByUserId(userId);
    }
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _matchError = null;
      _debugStatus = 'start matchmaking';
      _debugAttempts = 0;
    });
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () async {
      if (!mounted || _hasMatched || !_isConnecting) return;
      final queueId = _queuedQueueId;
      setState(() {
        _isConnecting = false;
        _matchError = 'Eslesme bulunamadi. Tekrar arayin.';
        _debugStatus = 'match timeout';
      });
      _retryTimer?.cancel();
      if (queueId != null) {
        await _matchmaking.leaveQueue(queueId);
      }
      await PresenceService.instance.clearActiveCity();
    });

    try {
      await PresenceService.instance.setActiveCity(widget.city.name);
      _setDebugStatus('presence ok');
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _matchmaking.clearQueueForUser(userId);
      }
      _queuedQueueId = await _matchmaking.enqueue(
        city: widget.city.name,
        cityKey: widget.city.matchKey,
      );
      _setDebugStatus('queued: $_queuedQueueId');
      final immediate = await _matchmaking.tryMatch(
        city: widget.city.name,
        cityKey: widget.city.matchKey,
        queueId: _queuedQueueId!,
      );
      if (immediate != null) {
        _setDebugStatus('immediate match');
        await _handleMatch(immediate);
        return;
      }
      _setDebugStatus('no immediate match');
      _matchSub?.cancel();
      _setDebugStatus('watching by queueId');
      _matchSub =
          _matchmaking.watchForMatch(_queuedQueueId!).listen((result) async {
        if (result == null || _hasMatched) return;
        await _handleMatch(result);
      });
      _startRetryTimer();
      final existing = await _matchmaking.getExistingMatch(_queuedQueueId!);
      if (existing != null && !_hasMatched) {
        _setDebugStatus('existing match found');
        await _handleMatch(existing);
        return;
      }
      if (userId != null) {
        final fallback = await _matchmaking.getExistingMatchByUserId(userId);
        if (fallback != null && !_hasMatched) {
          _setDebugStatus('existing match by userId');
          await _handleMatch(fallback);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _matchError = 'Eslesme basarisiz. Tekrar deneyin. ($error)';
        _debugStatus = 'start error: $error';
      });
      _retryTimer?.cancel();
    }
  }

  Future<void> _handleMatch(MatchResult result) async {
    _matchSub?.cancel();
    _retryTimer?.cancel();
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isConnecting = false;
    });
    PresenceService.instance.setActiveCity(widget.city.name);
    String? partnerName;
    String? roomCityKey;
    String? roomStatus;
    String? resolvedPartnerId;
    try {
      final roomSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(result.roomId)
          .get();
      final data = roomSnap.data();
      roomCityKey = data?['cityKey'] as String?;
      roomStatus = data?['status'] as String?;
      final participants = (data?['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      final userId = _auth.currentUser?.uid;
      if (userId != null && participants.isNotEmpty) {
        final derived =
            participants.firstWhere((id) => id != userId, orElse: () => '');
        if (derived.isNotEmpty) {
          resolvedPartnerId = derived;
        }
      }
      final names = data?['participantNames'];
      if (names is Map) {
        final name = names[resolvedPartnerId ?? result.partnerId];
        if (name is String && name.trim().isNotEmpty) {
          partnerName = name.trim();
        }
      }
    } catch (_) {
      // Ignore lookup failures and fall back to a generic label.
    }
    final effectivePartnerId = resolvedPartnerId ?? result.partnerId;
    if (roomStatus == 'rejected' || roomStatus == 'ended') {
      if (!mounted) return;
      setState(() {
        _matchError = 'Eslesme sonlandirildi. Tekrar deneyin.';
        _hasMatched = false;
      });
      return;
    }
    if (roomCityKey != null &&
        roomCityKey.isNotEmpty &&
        roomCityKey.toLowerCase() != widget.city.matchKey.toLowerCase()) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _hasMatched = false;
        _matchError = 'Sadece ayni sehirle eslesme yapilir.';
      });
      return;
    }
    _hasMatched = true;
    if (!mounted) return;
    if (roomStatus == 'active') {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => CallSessionScreen(
            city: widget.city,
            roomId: result.roomId,
            titleOverride: partnerName ??
                _matchmaking.partnerLabel(effectivePartnerId),
            forcedPartner:
                partnerName ?? _matchmaking.partnerLabel(effectivePartnerId),
            offererId: null,
          ),
        ),
      );
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => MatchAcceptScreen(
          city: widget.city,
          roomId: result.roomId,
          partnerId: effectivePartnerId,
          partnerName:
              partnerName ?? _matchmaking.partnerLabel(effectivePartnerId),
        ),
      ),
    );
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_hasMatched || !_isConnecting) return;
      if (_retryInFlight) return;
      final queueId = _queuedQueueId;
      if (queueId == null) return;
      _retryInFlight = true;
      _debugAttempts += 1;
      _setDebugStatus('retry #$_debugAttempts');
      try {
        final existing = await _matchmaking.getExistingMatch(queueId);
        if (existing != null && !_hasMatched) {
          _setDebugStatus('retry existing match');
          await _handleMatch(existing);
          return;
        }
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          final fallback = await _matchmaking.getExistingMatchByUserId(userId);
          if (fallback != null && !_hasMatched) {
            _setDebugStatus('retry match by userId');
            await _handleMatch(fallback);
            return;
          }
        }
        final result = await _matchmaking.tryMatch(
          city: widget.city.name,
          cityKey: widget.city.matchKey,
          queueId: queueId,
        );
        if (result != null && !_hasMatched) {
          _setDebugStatus('retry matched');
          await _handleMatch(result);
        } else if (result == null) {
          _setDebugStatus('retry no match');
        }
      } catch (error) {
        _setDebugStatus('retry error: $error');
      } finally {
        _retryInFlight = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundLayers(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: _atlasInk),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.city.name,
                        style: textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _atlasCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: withOpacity(_atlasTeal, 0.35),
                          ),
                        ),
                        child: Text(
                          'KAMERA YOK',
                          style: textTheme.bodyMedium?.copyWith(
                            color: _atlasInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _atlasCard,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: _atlasShadow,
                          blurRadius: 20,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: withOpacity(_atlasTeal, 0.15),
                                border: Border.all(
                                  color: withOpacity(_atlasTeal, 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: _atlasTeal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Otomatik eslesme',
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
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
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: withOpacity(_atlasAmber, 0.4),
                                ),
                              ),
                              child: Text(
                                'Anlik',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: _atlasInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ayni sehirden biriyle eslesir ve goruntusuz sesli sohbet baslar.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: withOpacity(_atlasInk, 0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _Pill(label: 'Anonim', color: _atlasTeal),
                            _Pill(label: 'Tek dokunus', color: _atlasAmber),
                            _Pill(label: 'Sesli', color: _atlasTeal),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: ConnectingCard(
                      isConnecting: _isConnecting,
                      accent: widget.city.accent,
                      errorMessage: _matchError,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<DatabaseEvent>(
                    stream: _database
                        .ref('presence')
                        .orderByChild('online')
                        .equalTo(true)
                        .onValue,
                    builder: (context, snapshot) {
                      int onlineCount = 0;
                      final raw = snapshot.data?.snapshot.value;
                      if (raw is Map) {
                        raw.forEach((_, value) {
                          if (value is Map) {
                            final city = value['city'];
                            if (city == widget.city.name) {
                              onlineCount += 1;
                            }
                          }
                        });
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: InfoTile(
                              label: 'Ortalama bekleme',
                              value: '14 sn',
                              icon: Icons.timelapse,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InfoTile(
                              label: 'Cevrimici',
                              value: '$onlineCount',
                              icon: Icons.waves,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _isConnecting ? null : _startMatchmaking,
                          style: FilledButton.styleFrom(
                            backgroundColor: _atlasAmber,
                            foregroundColor: _atlasInk,
                            elevation: 6,
                            shadowColor: withOpacity(_atlasAmber, 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _isConnecting
                                ? 'Eslesme araniyor...'
                                : 'Konusmayi baslat',
                            style: const TextStyle(
                              color: _atlasInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_matchError != null) const SizedBox(height: 10),

                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _atlasCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug info',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'userId: ${_auth.currentUser?.uid ?? 'null'}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: withOpacity(_atlasInk, 0.7),
                            ),
                          ),
                          Text(
                            'queueId: ${_queuedQueueId ?? 'null'}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: withOpacity(_atlasInk, 0.7),
                            ),
                          ),
                          Text(
                            'city: ${widget.city.name}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: withOpacity(_atlasInk, 0.7),
                            ),
                          ),
                          Text(
                            'cityKey: ${widget.city.matchKey}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: withOpacity(_atlasInk, 0.7),
                            ),
                          ),
                          Text(
                            'connecting: $_isConnecting',
                            style: textTheme.bodyMedium?.copyWith(
                              color: withOpacity(_atlasInk, 0.7),
                            ),
                          ),
                          Text(
                            'matched: $_hasMatched',
                            style: textTheme.bodyMedium?.copyWith(
                              color: withOpacity(_atlasInk, 0.7),
                            ),
                          ),
                          Text(
                            'status: ${_debugStatus ?? '-'}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: withOpacity(_atlasInk, 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Kurallar',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kisa ve net, sohbet guvende kalsin.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: withOpacity(_atlasInk, 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const RuleTile(
                    title: 'Otomatik eslesme',
                    subtitle: 'Sadece ayni sehirden biri atanir.',
                  ),
                  const RuleTile(
                    title: 'Anonim kal',
                    subtitle: 'Profil yok, kamera yok, sadece ses.',
                  ),
                  const RuleTile(
                    title: 'Sikayet kolay',
                    subtitle: 'Sorun yasarsan tek tikla bildir.',
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

class MatchAcceptScreen extends StatefulWidget {
  const MatchAcceptScreen({
    super.key,
    required this.city,
    required this.roomId,
    required this.partnerId,
    required this.partnerName,
  });

  final City city;
  final String roomId;
  final String partnerId;
  final String partnerName;

  @override
  State<MatchAcceptScreen> createState() => _MatchAcceptScreenState();
}

class _MatchAcceptScreenState extends State<MatchAcceptScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;
  Timer? _timeoutTimer;
  int _remainingSeconds = 15;
  bool _acceptedByMe = false;
  bool _otherAccepted = false;
  bool _handled = false;
  String? _resolvedPartnerId;

  @override
  void initState() {
    super.initState();
    _resolvedPartnerId = widget.partnerId;
    _ensureRoomAcceptanceState();
    _listenRoom();
    _startTimeout();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _remainingSeconds = 15;
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _handled) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        setState(() {
          _remainingSeconds = 0;
        });
        timer.cancel();
        _handleTimeout();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  String _resolvePartnerIdFromRoom(
    Map<String, dynamic> data,
    String? userId,
  ) {
    if (userId == null) {
      return _resolvedPartnerId ?? widget.partnerId;
    }
    final participants = (data['participants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    if (participants.isEmpty) {
      return _resolvedPartnerId ?? widget.partnerId;
    }
    final derived =
        participants.firstWhere((id) => id != userId, orElse: () => '');
    return derived.isNotEmpty
        ? derived
        : (_resolvedPartnerId ?? widget.partnerId);
  }

  Future<void> _ensureRoomAcceptanceState() async {
    final roomRef = _firestore.collection('rooms').doc(widget.roomId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(roomRef);
        final data = snap.data();
        if (data == null) return;
        final participants = (data['participants'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
        if (participants.isEmpty) return;
        final acceptedByRaw = data['acceptedBy'];
        final acceptedBy = <String, bool>{};
        if (acceptedByRaw is Map) {
          for (final entry in acceptedByRaw.entries) {
            acceptedBy[entry.key.toString()] = entry.value == true;
          }
        }
        bool changed = false;
        for (final id in participants) {
          if (!acceptedBy.containsKey(id)) {
            acceptedBy[id] = false;
            changed = true;
          }
        }
        if (changed) {
          transaction.set(roomRef, {'acceptedBy': acceptedBy},
              SetOptions(merge: true));
        }
      });
    } catch (_) {
      // Ignore hydration failures.
    }
  }

  Future<void> _handleTimeout() async {
    if (_otherAccepted) {
      return;
    }
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    final roomRef = _firestore.collection('rooms').doc(widget.roomId);
    try {
      final snap = await roomRef.get();
      final data = snap.data();
      if (data == null) {
        return;
      }
      final status = data['status'] as String? ?? 'pending';
      if (status == 'active' || status == 'rejected') {
        return;
      }
      final userId = _auth.currentUser?.uid;
      final partnerId = _resolvePartnerIdFromRoom(data, userId);
      final acceptedByRaw = data['acceptedBy'];
      bool other = false;
      if (acceptedByRaw is Map && partnerId.isNotEmpty) {
        other = acceptedByRaw[partnerId] == true;
      }
      if (other) {
        if (mounted) {
          setState(() {
            _otherAccepted = true;
          });
        } else {
          _otherAccepted = true;
        }
        return;
      }
      await roomRef.set({'status': 'active'}, SetOptions(merge: true));
      if (!mounted) return;
      _handled = true;
      _openCall();
      return;
    } catch (_) {
      // Ignore lookup failures and fall back to local timeout handling.
    }
    if (!mounted) return;
    _handled = true;
    _openCall();
  }

  void _listenRoom() {
    final roomRef = _firestore.collection('rooms').doc(widget.roomId);
    _roomSub = roomRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        if (!_handled && mounted) {
          Navigator.of(context).maybePop();
        }
        return;
      }
      final status = data['status'] as String? ?? 'pending';
      if (status == 'active') {
        if (!_handled) {
          _handled = true;
          _timeoutTimer?.cancel();
          _openCall();
        }
        return;
      }
      if (status == 'rejected') {
        if (!_handled && mounted) {
          _handled = true;
          _timeoutTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Eslesme reddedildi.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).maybePop();
        }
        return;
      }
      final userId = _auth.currentUser?.uid;
      final partnerId = _resolvePartnerIdFromRoom(data, userId);
      if (partnerId.isNotEmpty && partnerId != _resolvedPartnerId) {
        if (mounted) {
          setState(() {
            _resolvedPartnerId = partnerId;
          });
        } else {
          _resolvedPartnerId = partnerId;
        }
      }
      final acceptedBy = data['acceptedBy'];
      if (acceptedBy is Map) {
        final me = userId != null && acceptedBy[userId] == true;
        final other = partnerId.isNotEmpty && acceptedBy[partnerId] == true;
        if ((me != _acceptedByMe || other != _otherAccepted) && mounted) {
          setState(() {
            _acceptedByMe = me;
            _otherAccepted = other;
          });
        }
        if (me && other && status != 'active') {
          _firestore.collection('rooms').doc(widget.roomId).set(
            {'status': 'active'},
            SetOptions(merge: true),
          );
        }
      }
    });
  }

  Future<void> _acceptMatch() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    if (_acceptedByMe) return;
    final roomRef = _firestore.collection('rooms').doc(widget.roomId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(roomRef);
        final data = snap.data() ?? {};
        final acceptedByRaw = data['acceptedBy'];
        final acceptedBy = <String, bool>{};
        if (acceptedByRaw is Map) {
          for (final entry in acceptedByRaw.entries) {
            acceptedBy[entry.key.toString()] = entry.value == true;
          }
        }
        acceptedBy[userId] = true;
        final participants = (data['participants'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
        for (final id in participants) {
          acceptedBy.putIfAbsent(id, () => false);
        }
        final effectiveParticipants =
            participants.isNotEmpty ? participants : acceptedBy.keys.toList();
        final allAccepted = effectiveParticipants.isNotEmpty &&
            effectiveParticipants.every((id) => acceptedBy[id] == true);
        final update = <String, dynamic>{
          'acceptedBy': acceptedBy,
        };
        if (allAccepted) {
          update['status'] = 'active';
        }
        transaction.set(roomRef, update, SetOptions(merge: true));
      });
      if (!mounted) return;
      setState(() {
        _acceptedByMe = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onayin gonderildi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eslesme onayi gonderilemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectMatch() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore.collection('rooms').doc(widget.roomId).set(
        {
          'status': 'rejected',
          'rejectedBy': userId,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Ignore reject failures.
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _openCall() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallSessionScreen(
          city: widget.city,
          roomId: widget.roomId,
          titleOverride: widget.partnerName,
          forcedPartner: widget.partnerName,
          offererId: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundLayers(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _rejectMatch,
                        icon: const Icon(Icons.arrow_back, color: _atlasInk),
                      ),
                      const SizedBox(width: 4),
                      Text('Eslesme', style: textTheme.titleLarge),
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
                    child: const Icon(Icons.person, color: _atlasTeal, size: 56),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.partnerName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otherAccepted
                        ? 'Karsi taraf kabul etti.'
                        : 'Karsi tarafin onayi bekleniyor.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: withOpacity(_atlasInk, 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_remainingSeconds sn icinde yanit verilmeli',
                    style: textTheme.bodyMedium?.copyWith(
                      color: withOpacity(_atlasInk, 0.6),
                    ),
                  ),
                  if (_acceptedByMe) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Onayin gonderildi. Bekleniyor...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: withOpacity(_atlasInk, 0.6),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rejectMatch,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: withOpacity(_atlasTeal, 0.45)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Pas gec'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _acceptedByMe ? null : _acceptMatch,
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

class CallSessionScreen extends StatefulWidget {
  const CallSessionScreen({
    super.key,
    required this.city,
    this.roomId,
    this.titleOverride,
    this.forcedPartner,
    this.offererId,
    this.fromFriendsCall = false,
  });

  final City city;
  final String? roomId;
  final String? titleOverride;
  final String? forcedPartner;
  final String? offererId;
  final bool fromFriendsCall;

  @override
  State<CallSessionScreen> createState() => _CallSessionScreenState();
}

class _CallSessionScreenState extends State<CallSessionScreen> {
  static const int _sessionSeconds = 90;
  int _remainingSeconds = _sessionSeconds;
  bool _sessionEnded = false;
  bool _speakerOn = true;
  bool _fixedPartner = false;
  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _seenCandidateIds = {};
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCVideoRenderer? _remoteRenderer;
  String _rtcConnection = '-';
  String _rtcIce = '-';
  String _rtcSignal = '-';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _partnerProfileSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candidateSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingCallSub;
  DocumentReference<Map<String, dynamic>>? _roomRef;
  bool _isOfferer = false;
  bool _remoteDescriptionSet = false;
  bool _localDescriptionSet = false;
  String? _partnerId;
  String? _incomingCallRoomId;

  final List<String> _partners = const [
    'Deniz',
    'Mert',
    'Ece',
    'Arda',
    'Selin',
    'Kaan',
  ];

  late String _partnerName;

  void _setRtcState({
    String? connection,
    String? ice,
    String? signaling,
  }) {
    if (!mounted) return;
    setState(() {
      if (connection != null) _rtcConnection = connection;
      if (ice != null) _rtcIce = ice;
      if (signaling != null) _rtcSignal = signaling;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.forcedPartner != null) {
      _partnerName = widget.forcedPartner!;
      _fixedPartner = true;
    } else {
      _partnerName = _partners[math.Random().nextInt(_partners.length)];
    }
    _startConnecting();
    _initRenderers();
    _initRtc();
    _listenIncomingCalls();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _partnerProfileSub?.cancel();
    _candidateSub?.cancel();
    _incomingCallSub?.cancel();
    _disposeRtc();
    _remoteRenderer?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startConnecting() {
    _pickNewPartner();
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _sessionSeconds;
      _sessionEnded = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        _endCall();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _pickNewPartner() {
    if (_fixedPartner) return;
    _partnerName = _partners[math.Random().nextInt(_partners.length)];
  }

  Future<void> _initRenderers() async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    if (!mounted) {
      await renderer.dispose();
      return;
    }
    setState(() {
      _remoteRenderer = renderer;
    });
    if (_remoteStream != null) {
      _remoteRenderer?.srcObject = _remoteStream;
    }
  }

  void _listenIncomingCalls() {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    _incomingCallSub?.cancel();
    _incomingCallSub = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('call_requests')
        .where('status', isEqualTo: 'pending')
        .where('direction', isEqualTo: 'incoming')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final roomId = (data['roomId'] as String?) ?? doc.id;
        if (roomId.isEmpty || roomId == widget.roomId) {
          continue;
        }
        if (_incomingCallRoomId == roomId) {
          continue;
        }
        final callerId = data['callerId'] as String?;
        final calleeId = data['calleeId'] as String?;
        if (callerId == null || calleeId == null) {
          continue;
        }
        final partnerName =
            (data['otherUserName'] as String?) ?? 'Kullanici';
        final fromFriendsCall = data['fromFriendsCall'] == true;
        _incomingCallRoomId = roomId;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => CallInviteScreen.incoming(
              roomId: roomId,
              callerId: callerId,
              calleeId: calleeId,
              partnerName: partnerName,
              fromFriendsCall: fromFriendsCall,
            ),
          ),
        );
        break;
      }
    });
  }

  Future<void> _requestRematch() async {
    final user = _auth.currentUser;
    final partnerId = _partnerId;
    if (user == null || partnerId == null || partnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama baslatilamadi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final firestore = _firestore;
    final roomRef = firestore.collection('rooms').doc();
    final roomId = roomRef.id;

    final batch = firestore.batch();
    batch.set(
      roomRef,
      {
        'participants': [user.uid, partnerId],
        'participantNames': {
          user.uid: user.displayName ?? 'Kullanici',
          partnerId: _partnerName,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      },
      SetOptions(merge: true),
    );

    final incomingRef = firestore
        .collection('users')
        .doc(partnerId)
        .collection('call_requests')
        .doc(roomId);
    batch.set(
      incomingRef,
      {
        'roomId': roomId,
        'callerId': user.uid,
        'calleeId': partnerId,
        'direction': 'incoming',
        'status': 'pending',
        'otherUserId': user.uid,
        'otherUserName': user.displayName ?? 'Kullanici',
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
        'calleeId': partnerId,
        'direction': 'outgoing',
        'status': 'pending',
        'otherUserId': partnerId,
        'otherUserName': _partnerName,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arama istegi gonderildi: $_partnerName'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => CallInviteScreen.outgoing(
            roomId: roomId,
            callerId: user.uid,
            calleeId: partnerId,
            partnerName: _partnerName,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama istegi gonderilemedi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    final message = status.isPermanentlyDenied
        ? 'Mikrofon izni kapali. Ayarlardan acin.'
        : 'Mikrofon izni gerekli.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _initRtc() async {
    final roomId = widget.roomId;
    final user = _auth.currentUser;
    if (roomId == null || user == null) {
      return;
    }

    if (!await _ensureMicrophonePermission()) {
      return;
    }
    await _roomSub?.cancel();
    await _candidateSub?.cancel();
    _roomSub = null;
    _candidateSub = null;
    _seenCandidateIds.clear();
    _remoteDescriptionSet = false;
    _localDescriptionSet = false;
    await _disposeRtc();
    if (_remoteRenderer == null) {
      await _initRenderers();
    }

    final roomRef = _firestore.collection('rooms').doc(roomId);
    _roomRef = roomRef;
    final roomSnap = await roomRef.get();
    final data = roomSnap.data();
    if (data == null) {
      return;
    }

    final participants = (data['participants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    if (participants.length < 2) {
      return;
    }

    if (widget.offererId != null && widget.offererId!.isNotEmpty) {
      _isOfferer = widget.offererId == user.uid;
    } else {
      final sorted = [...participants]..sort();
      _isOfferer = sorted.isNotEmpty && sorted.first == user.uid;
    }
    _partnerId = participants.firstWhere(
      (id) => id != user.uid,
      orElse: () => '',
    );
    final names = data['participantNames'];
    if (names is Map && _partnerId != null && _partnerId!.isNotEmpty) {
      final partnerName = names[_partnerId];
      if (partnerName is String && partnerName.trim().isNotEmpty) {
        _partnerName = partnerName.trim();
      }
    }
    _subscribePartnerProfile();
    await _setupPeerConnection();

    _roomSub = roomRef.snapshots().listen((snapshot) {
      final roomData = snapshot.data();
      if (roomData == null) {
        return;
      }
      final names = roomData['participantNames'];
      if (names is Map && _partnerId != null && _partnerId!.isNotEmpty) {
        final partnerName = names[_partnerId];
        if (partnerName is String &&
            partnerName.trim().isNotEmpty &&
            partnerName != _partnerName) {
          setState(() {
            _partnerName = partnerName.trim();
          });
        }
      }
      final status = roomData['status'];
      if (status == 'ended' && !_sessionEnded) {
        _handleRemoteEnd();
      }
      if (_isOfferer) {
        final answer = roomData['answer'];
        if (!_remoteDescriptionSet && answer is Map<String, dynamic>) {
          final sdp = answer['sdp'] as String?;
          final type = answer['type'] as String?;
          if (sdp != null && type != null) {
            _peerConnection
                ?.setRemoteDescription(RTCSessionDescription(sdp, type));
            _remoteDescriptionSet = true;
          }
        }
      } else {
        final offer = roomData['offer'];
        if (!_remoteDescriptionSet && offer is Map<String, dynamic>) {
          final sdp = offer['sdp'] as String?;
          final type = offer['type'] as String?;
          if (sdp != null && type != null) {
            _peerConnection
                ?.setRemoteDescription(RTCSessionDescription(sdp, type));
            _remoteDescriptionSet = true;
            _createAnswer(roomRef);
          }
        }
      }
    });

    _candidateSub = roomRef.collection('candidates').snapshots().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) {
            continue;
          }
          if (_seenCandidateIds.contains(change.doc.id)) {
            continue;
          }
          _seenCandidateIds.add(change.doc.id);
          final data = change.doc.data();
          if (data == null) {
            continue;
          }
          if (data['senderId'] == user.uid) {
            continue;
          }
          final candidate = data['candidate'] as String?;
          final sdpMid = data['sdpMid'] as String?;
          final sdpMLineIndex = data['sdpMLineIndex'] as int?;
          if (candidate == null) {
            continue;
          }
          _peerConnection?.addCandidate(
            RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
          );
        }
      },
    );

    if (_isOfferer) {
      await _createOffer(roomRef);
    }
  }

  void _subscribePartnerProfile() {
    final partnerId = _partnerId;
    if (partnerId == null || partnerId.isEmpty) {
      return;
    }
    _partnerProfileSub?.cancel();
    _partnerProfileSub = _firestore
        .collection('users')
        .doc(partnerId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      final name = data?['name'];
      if (name is String && name.trim().isNotEmpty) {
        final trimmed = name.trim();
        if (trimmed != _partnerName && mounted) {
          setState(() {
            _partnerName = trimmed;
          });
        }
      }
    });
  }

  Future<String?> _resolvePartnerIdForFriend() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    if (_partnerId != null && _partnerId!.isNotEmpty) {
      return _partnerId;
    }
    final roomId = widget.roomId;
    if (roomId == null || roomId.isEmpty) {
      return null;
    }
    try {
      final snap = await _firestore.collection('rooms').doc(roomId).get();
      final data = snap.data();
      if (data == null) return null;
      final participants = (data['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      final partnerId =
          participants.firstWhere((id) => id != user.uid, orElse: () => '');
      if (partnerId.isEmpty) return null;
      final names = data['participantNames'];
      if (names is Map) {
        final partnerName = names[partnerId];
        if (partnerName is String && partnerName.trim().isNotEmpty) {
          _partnerName = partnerName.trim();
        }
      }
      if (mounted) {
        setState(() {
          _partnerId = partnerId;
        });
      } else {
        _partnerId = partnerId;
      }
      return partnerId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _addFriend() async {
    final user = _auth.currentUser;
    final partnerId = await _resolvePartnerIdForFriend();
    if (!mounted) return;
    if (user == null || partnerId == null || partnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arkadas eklenemedi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final requests = _firestore.collection('friend_requests');
      final incomingRequest = await requests
          .where('senderId', isEqualTo: partnerId)
          .where('recipientId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (incomingRequest.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zaten istek var. Isteklerden kabul et.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final outgoingRequest = await requests
          .where('senderId', isEqualTo: user.uid)
          .where('recipientId', isEqualTo: partnerId)
          .limit(1)
          .get();
      if (outgoingRequest.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Istek zaten gonderildi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final existingFriend = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .doc(partnerId)
          .get();
      if (existingFriend.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zaten arkadassiniz: $_partnerName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      String senderName = 'Kullanici';
      try {
        final profileSnap =
            await _firestore.collection('users').doc(user.uid).get();
        final data = profileSnap.data();
        final name = data?['name'];
        if (name is String && name.trim().isNotEmpty) {
          senderName = name.trim();
        }
      } catch (_) {
        // Ignore profile lookup errors.
      }

      final requestId = '${user.uid}_$partnerId';
      await requests.doc(requestId).set(
        {
          'senderId': user.uid,
          'senderName': senderName,
          'recipientId': partnerId,
          'roomId': widget.roomId,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arkadaslik istegi gonderildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arkadas eklenemedi: ${error.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arkadas eklenemedi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setupPeerConnection() async {
    final roomRef = _roomRef;
    if (roomRef == null) {
      return;
    }

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };
    final pc = await createPeerConnection(config);
    _peerConnection = pc;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = true;
    }
    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onTrack = (event) {
      if (event.track.kind == 'audio') {
        event.track.enabled = true;
        Helper.setSpeakerphoneOn(_speakerOn);
      }
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteRenderer?.srcObject = _remoteStream;
        for (final track in _remoteStream!.getAudioTracks()) {
          track.enabled = true;
        }
      }
    };
    pc.onAddStream = (stream) {
      _remoteStream = stream;
      _remoteRenderer?.srcObject = _remoteStream;
      for (final track in _remoteStream!.getAudioTracks()) {
        track.enabled = true;
      }
    };
    pc.onConnectionState = (state) {
      debugPrint('RTC connection state: $state');
      _setRtcState(connection: state.toString());
    };
    pc.onIceConnectionState = (state) {
      debugPrint('RTC ICE state: $state');
      _setRtcState(ice: state.toString());
    };
    pc.onSignalingState = (state) {
      debugPrint('RTC signaling state: $state');
      _setRtcState(signaling: state.toString());
    };

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) {
        return;
      }
      roomRef.collection('candidates').add({
        'senderId': _auth.currentUser?.uid,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'createdAt': FieldValue.serverTimestamp(),
      });
    };

    final tracks = _localStream?.getAudioTracks() ?? const [];
    if (tracks.isNotEmpty) {
      await Helper.setMicrophoneMute(false, tracks.first);
    }
    await Helper.setSpeakerphoneOn(_speakerOn);
  }

  Future<void> _createOffer(
      DocumentReference<Map<String, dynamic>> roomRef) async {
    if (_peerConnection == null || _localDescriptionSet) {
      return;
    }
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _localDescriptionSet = true;
    await roomRef.set(
      {
        'offer': offer.toMap(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _createAnswer(
      DocumentReference<Map<String, dynamic>> roomRef) async {
    if (_peerConnection == null || _localDescriptionSet) {
      return;
    }
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    _localDescriptionSet = true;
    await roomRef.set(
      {
        'answer': answer.toMap(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _endCall() async {
    if (_sessionEnded) {
      return;
    }
    final roomRef = _roomRef;
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionEnded = true;
    });
    _timer?.cancel();
    if (roomRef != null) {
      await roomRef.set(
        {
          'status': 'ended',
          'endedBy': _auth.currentUser?.uid,
          'endedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await PresenceService.instance.clearActiveCity();
    await _disposeRtc();
  }

  void _handleRemoteEnd() {
    if (_sessionEnded) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionEnded = true;
    });
    _timer?.cancel();
    PresenceService.instance.clearActiveCity();
    _disposeRtc();
  }

  Future<void> _disposeRtc() async {
    try {
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _peerConnection?.close();
    } catch (_) {
      // Ignore cleanup errors.
    }
    _localStream = null;
    _remoteStream = null;
    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = null;
    }
    _peerConnection = null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayTitle = widget.titleOverride ?? widget.city.name;
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final progress =
        1 - (_remainingSeconds / _sessionSeconds).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          const SimpleBackground(),
          if (_remoteRenderer != null)
            Offstage(
              offstage: true,
              child: RTCVideoView(_remoteRenderer!),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back, color: _atlasInk),
                    ),
                    const SizedBox(width: 4),
                    Text(displayTitle, style: textTheme.titleLarge),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _atlasCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: withOpacity(_atlasTeal, 0.35),
                        ),
                      ),
                      child: Text(
                        'CANLI',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _atlasInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: _atlasCard,
                    border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: _atlasShadow,
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_sessionEnded) ...[
                        Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: withOpacity(_atlasTeal, 0.15),
                                border: Border.all(
                                  color: withOpacity(_atlasTeal, 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: _atlasTeal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gorusme bitti',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Yeni bir eslesme icin yeniden baslat.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: withOpacity(_atlasInk, 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: withOpacity(_atlasTeal, 0.15),
                                border: Border.all(
                                  color: withOpacity(_atlasTeal, 0.3),
                                ),
                              ),
                              child:
                                  const Icon(Icons.person, color: _atlasTeal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _partnerName,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Arama devam ediyor',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: withOpacity(_atlasInk, 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$minutes:$seconds',
                          style: textTheme.headlineLarge?.copyWith(
                            fontSize: 34,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: withOpacity(_atlasTeal, 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              withOpacity(_atlasTeal, 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _sessionEnded ? _requestRematch : _endCall,
                    style: FilledButton.styleFrom(
                      backgroundColor: _atlasAmber,
                      foregroundColor: _atlasInk,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _sessionEnded ? 'Tekrar ara' : 'Konusmayi bitir',
                      style: const TextStyle(
                        color: _atlasInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RTC: $_rtcConnection | ICE: $_rtcIce | SDP: $_rtcSignal',
                  style: textTheme.bodySmall?.copyWith(
                    color: withOpacity(_atlasInk, 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!widget.fromFriendsCall)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addFriend,
                          style: OutlinedButton.styleFrom(
                            side:
                                BorderSide(color: withOpacity(_atlasTeal, 0.45)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.person_add, color: _atlasInk),
                          label: Text(
                            'Arkadas ekle',
                            style: textTheme.bodyMedium?.copyWith(
                              color: _atlasInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (!widget.fromFriendsCall) const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _speakerOn = !_speakerOn;
                          });
                          Helper.setSpeakerphoneOn(_speakerOn);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: withOpacity(_atlasTeal, 0.45)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          _speakerOn ? Icons.volume_up : Icons.volume_off,
                          color: _atlasInk,
                        ),
                        label: Text(
                          _speakerOn ? 'Hoparlor acik' : 'Hoparlor ac',
                          style: textTheme.bodyMedium?.copyWith(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: withOpacity(color, 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: withOpacity(color, 0.4),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _atlasInk,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class ConnectingCard extends StatelessWidget {
  const ConnectingCard({
    super.key,
    required this.isConnecting,
    required this.accent,
    this.errorMessage,
  });

  final bool isConnecting;
  final Color accent;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    final title = hasError
        ? 'Eslesme bulunamadi'
        : (isConnecting ? 'Eslesme araniyor' : 'Baglanti hazir');
    final subtitle = hasError
        ? errorMessage!.trim()
        : (isConnecting
            ? 'Kisa sure icinde birini bulacagiz.'
            : 'Sohbete baslamak icin hazirsin.');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _atlasCard,
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
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: withOpacity(_atlasTeal, 0.12),
              border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
            ),
            child: Icon(
              hasError
                  ? Icons.error_outline
                  : (isConnecting ? Icons.podcasts : Icons.check),
              color: hasError ? Colors.redAccent : _atlasTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: hasError
                        ? Colors.redAccent
                        : withOpacity(_atlasInk, 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (isConnecting && !hasError) const WaveBars(),
        ],
      ),
    );
  }
}

class ConnectedCard extends StatelessWidget {
  const ConnectedCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _atlasCard,
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: withOpacity(_atlasTeal, 0.15),
              border: Border.all(color: withOpacity(_atlasTeal, 0.3)),
            ),
            child: const Icon(Icons.person, color: _atlasTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sohbet devam ediyor',
                  style: textTheme.bodyMedium?.copyWith(
                    color: withOpacity(_atlasInk, 0.65),
                  ),
                ),
              ],
            ),
          ),
          const WaveBars(),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: withOpacity(_atlasTeal, 0.12),
              border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
            ),
            child: Icon(icon, color: _atlasTeal, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: withOpacity(_atlasInk, 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RuleTile extends StatelessWidget {
  const RuleTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: withOpacity(_atlasTeal, 0.15),
              border: Border.all(color: withOpacity(_atlasTeal, 0.3)),
            ),
            child: const Icon(Icons.check, color: _atlasTeal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: withOpacity(_atlasInk, 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveBars extends StatefulWidget {
  const WaveBars({super.key});

  @override
  State<WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<WaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          children: List.generate(3, (index) {
            final phase = (_controller.value * 2 * math.pi) + (index * 0.6);
            final height = 12 + (18 * (0.5 + 0.5 * math.sin(phase)));
            return Container(
              width: 10,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: withOpacity(_atlasTeal, 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        );
      },
    );
  }
}
