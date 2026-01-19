import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseReference get _rootRef => _database.ref();

  String? _currentCity;
  String? _lastCity;
  bool _started = false;
  bool _isPaused = false;
  bool _countsApplied = false;
  bool _onlineApplied = false;
  StreamSubscription<DatabaseEvent>? _connectedSub;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _listenConnection();
    _setOnline(true);
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    await _connectedSub?.cancel();
    _connectedSub = null;
  }

  void _listenConnection() {
    _connectedSub = _database.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value == true;
      if (connected) {
        if (_isPaused) return;
        if (!_onlineApplied) {
          _setOnline(true);
        }
        final city = _currentCity;
        if (city != null && !_countsApplied) {
          setActiveCity(city);
        }
        _syncPresence();
      } else {
        _countsApplied = false;
        _onlineApplied = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      _setOnline(true);
      final city = _lastCity;
      if (city != null) {
        setActiveCity(city);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _isPaused = true;
      clearActiveCity();
      _setOnline(false);
    }
  }

  Future<void> setActiveCity(String city) async {
    if (_isPaused) return;
    await _setOnline(true);
    if (_currentCity == city && _countsApplied) return;
    if (_currentCity != null && _countsApplied) {
      await _updateCityCount(_currentCity!, -1);
    }
    _currentCity = city;
    _lastCity = city;
    await _updateCityCount(city, 1);
    _countsApplied = true;
    await _configureOnDisconnect();
    await _syncPresence();
  }

  Future<void> clearActiveCity() async {
    if (_currentCity == null) return;
    final previous = _currentCity!;
    _currentCity = null;
    if (_countsApplied) {
      await _updateCityCount(previous, -1);
      _countsApplied = false;
    }
    await _configureOnDisconnect();
    await _syncPresence();
  }

  Future<void> _setOnline(bool online) async {
    if (_isPaused && online) return;
    if (online) {
      if (_onlineApplied) return;
      await _updateTotal(1);
      _onlineApplied = true;
    } else {
      if (!_onlineApplied) return;
      await _updateTotal(-1);
      _onlineApplied = false;
    }
    await _configureOnDisconnect();
    await _syncPresence();
  }

  Future<void> _updateCityCount(String city, int delta) async {
    final updates = <String, Object?>{
      'city_counts/$city': ServerValue.increment(delta),
    };
    await _rootRef.update(updates);
  }

  Future<void> _updateTotal(int delta) async {
    await _rootRef.update({
      'stats/total': ServerValue.increment(delta),
    });
  }

  Future<void> _configureOnDisconnect() async {
    await _rootRef.onDisconnect().cancel();
    final updates = <String, Object?>{};
    if (_onlineApplied) {
      updates['stats/total'] = ServerValue.increment(-1);
    }
    if (_countsApplied && _currentCity != null) {
      updates['city_counts/$_currentCity'] = ServerValue.increment(-1);
    }
    if (updates.isEmpty) {
      return;
    }
    await _rootRef.onDisconnect().update(updates);
  }

  Future<void> _syncPresence() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final presenceRef = _database.ref('presence/${user.uid}');
    await presenceRef.set({
      'online': _onlineApplied,
      'city': _currentCity,
      'updatedAt': ServerValue.timestamp,
    });
    await presenceRef.onDisconnect().update({
      'online': false,
      'updatedAt': ServerValue.timestamp,
    });
  }
}
