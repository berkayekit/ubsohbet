import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchResult {
  const MatchResult({
    required this.roomId,
    required this.partnerId,
  });

  final String roomId;
  final String partnerId;
}

class MatchmakingService {
  MatchmakingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _queue =>
      _firestore.collection('match_queue');
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  static const Map<String, String> _cityKeyReplacements = {
    '\u00e7': 'c',
    '\u00c7': 'c',
    '\u011f': 'g',
    '\u011e': 'g',
    '\u0131': 'i',
    '\u0130': 'i',
    '\u00f6': 'o',
    '\u00d6': 'o',
    '\u015f': 's',
    '\u015e': 's',
    '\u00fc': 'u',
    '\u00dc': 'u',
  };

  String _cityKey(String city) {
    final buffer = StringBuffer();
    for (final rune in city.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_cityKeyReplacements[char] ?? char.toLowerCase());
    }
    return buffer.toString().trim().toLowerCase();
  }

  String _cityKeyFromData(Map<String, dynamic> data) {
    final key = data['cityKey'];
    if (key is String && key.isNotEmpty) {
      return key.trim().toLowerCase();
    }
    return '';
  }

  bool _matchesCity(
    Map<String, dynamic> data,
    String city,
    String resolvedCityKey,
  ) {
    final dataKey = _cityKeyFromData(data);
    return dataKey.isNotEmpty && dataKey == resolvedCityKey;
  }


  Future<String> enqueue({required String city, String? cityKey}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('AUTH_REQUIRED');
    }

    final resolvedCityKey = (cityKey != null && cityKey.trim().isNotEmpty)
        ? cityKey.trim().toLowerCase()
        : _cityKey(city);
    if (resolvedCityKey.isEmpty) {
      throw StateError('CITY_KEY_REQUIRED');
    }

    String? displayName;
    try {
      final userSnap = await _firestore.collection('users').doc(user.uid).get();
      final data = userSnap.data();
      final name = data?['name'];
      if (name is String && name.trim().isNotEmpty) {
        displayName = name.trim();
      }
    } catch (_) {
      // Ignore profile lookup errors and fall back to default label.
    }

    final ref = _queue.doc();
    await ref.set({
      'userId': user.uid,
      'city': city,
      'cityKey': resolvedCityKey,
      'name': displayName ?? 'Kullanici',
      'status': 'waiting',
      'createdAt': Timestamp.now(),
      'roomId': null,
      'partnerId': null,
    }, SetOptions(merge: true));
    return ref.id;
  }

  Future<MatchResult?> tryMatch({
    required String city,
    required String queueId,
    String? cityKey,
  }) async {
    final selfRef = _queue.doc(queueId);
    final resolvedCityKey = (cityKey != null && cityKey.trim().isNotEmpty)
        ? cityKey.trim().toLowerCase()
        : _cityKey(city);
    if (resolvedCityKey.isEmpty) {
      return null;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? candidate;

    Future<QuerySnapshot<Map<String, dynamic>>> loadCandidates(
      String? field,
      String? value,
    ) async {
      final limit = field == null ? 12 : 6;
      try {
        Query<Map<String, dynamic>> query =
            _queue.where('status', isEqualTo: 'waiting');
        if (field != null && value != null) {
          query = query.where(field, isEqualTo: value);
        }
        query = query.orderBy('createdAt').limit(limit);
        return await query.get(const GetOptions(source: Source.server));
      } on FirebaseException catch (error) {
        if (error.code != 'failed-precondition' &&
            error.code != 'invalid-argument') {
          rethrow;
        }
        Query<Map<String, dynamic>> fallback =
            _queue.where('status', isEqualTo: 'waiting');
        if (field != null && value != null) {
          fallback = fallback.where(field, isEqualTo: value);
        }
        fallback = fallback.limit(limit);
        return await fallback.get(const GetOptions(source: Source.server));
      }
    }

    final querySpecs = <List<String?>>[
      ['cityKey', resolvedCityKey],
      if (resolvedCityKey.isEmpty) ['city', city],
    ];

    for (final spec in querySpecs) {
      final snapshot = await loadCandidates(spec[0], spec[1]);
      for (final doc in snapshot.docs) {
        if (doc.id == queueId) continue;
        final data = doc.data();
        final candidateUserId = data['userId'];
        if (!_matchesCity(data, city, resolvedCityKey)) {
          continue;
        }
        if (candidateUserId is String &&
            candidateUserId == _auth.currentUser?.uid) {
          continue;
        }
        candidate = doc;
        break;
      }
      if (candidate != null) {
        break;
      }
    }

    if (candidate == null) {
      return null;
    }
    final selected = candidate;

    return _firestore.runTransaction((transaction) async {
      final selfSnap = await transaction.get(selfRef);
      final candidateSnap = await transaction.get(selected.reference);
      if (!selfSnap.exists || !candidateSnap.exists) {
        return null;
      }
      final selfData = selfSnap.data() as Map<String, dynamic>;
      final candidateData = candidateSnap.data() as Map<String, dynamic>;
      final selfUserId = selfData['userId'] as String?;
      final candidateUserId = candidateData['userId'] as String?;
      if (selfUserId == null || candidateUserId == null) {
        return null;
      }
      final selfMatchesCity = _matchesCity(selfData, city, resolvedCityKey);
      final candidateMatchesCity =
          _matchesCity(candidateData, city, resolvedCityKey);
      if (!selfMatchesCity || !candidateMatchesCity) {
        return null;
      }
      if (selfData['status'] != 'waiting' ||
          candidateData['status'] != 'waiting' ||
          selfUserId == candidateUserId) {
        return null;
      }

      final roomRef = _rooms.doc();
      final selfName = selfData['name'] ?? 'Kullanici';
      final candidateName = candidateData['name'] ?? 'Kullanici';
      transaction.set(roomRef, {
        'city': city,
        'cityKey': resolvedCityKey,
        'participants': [selfUserId, candidateUserId],
        'participantNames': {
          selfUserId: selfName,
          candidateUserId: candidateName,
        },
        'createdAt': Timestamp.now(),
        'status': 'pending',
        'acceptedBy': {
          selfUserId: false,
          candidateUserId: false,
        },
      });
      transaction.update(selected.reference, {
        'status': 'matched',
        'roomId': roomRef.id,
        'partnerId': selfUserId,
      });
      transaction.update(selfRef, {
        'status': 'matched',
        'roomId': roomRef.id,
        'partnerId': candidateUserId,
      });
      return MatchResult(roomId: roomRef.id, partnerId: candidateUserId);
    });
  }

  Stream<MatchResult?> watchForMatch(String queueId) {
    return _queue.doc(queueId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      if (data['status'] != 'matched') return null;
      final roomId = data['roomId'] as String?;
      final partnerId = data['partnerId'] as String?;
      if (roomId == null || partnerId == null) return null;
      return MatchResult(roomId: roomId, partnerId: partnerId);
    });
  }

  Stream<MatchResult?> watchForMatchByUserId(String userId) {
    return _queue
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] != 'matched') continue;
        final roomId = data['roomId'] as String?;
        final partnerId = data['partnerId'] as String?;
        if (roomId == null || partnerId == null) continue;
        return MatchResult(roomId: roomId, partnerId: partnerId);
      }
      return null;
    });
  }

  Future<MatchResult?> getExistingMatch(String queueId) async {
    final snapshot =
        await _queue.doc(queueId).get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data == null) return null;
    if (data['status'] != 'matched') return null;
    final roomId = data['roomId'] as String?;
    final partnerId = data['partnerId'] as String?;
    if (roomId == null || partnerId == null) return null;
    return MatchResult(roomId: roomId, partnerId: partnerId);
  }

  Future<MatchResult?> getExistingMatchByUserId(String userId) async {
    final snapshot = await _queue
        .where('userId', isEqualTo: userId)
        .get(const GetOptions(source: Source.server));
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] != 'matched') continue;
      final roomId = data['roomId'] as String?;
      final partnerId = data['partnerId'] as String?;
      if (roomId == null || partnerId == null) continue;
      return MatchResult(roomId: roomId, partnerId: partnerId);
    }
    return null;
  }

  Future<void> leaveQueue(String queueId) async {
    await _queue.doc(queueId).delete();
  }

  Future<void> leaveQueueByUserId(String userId) async {
    final snapshot = await _queue
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'waiting')
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> clearQueueForUser(String userId) async {
    final snapshot = await _queue.where('userId', isEqualTo: userId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  String partnerLabel(String partnerId) {
    if (partnerId.length <= 6) {
      return 'Kullanici $partnerId';
    }
    return 'Kullanici ${partnerId.substring(0, 6)}';
  }
}
