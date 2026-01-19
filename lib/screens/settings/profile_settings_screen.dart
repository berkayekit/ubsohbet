import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const List<_AvatarOption> _avatarOptions = [
    _AvatarOption(
      label: 'Erkek 1',
      style: _AvatarStyle(
        background: Color(0xFF1F7A74),
        skin: Color(0xFFF2C7A8),
        hair: Color(0xFF2B1D14),
        shirt: Color(0xFF2C3E50),
        hairStyle: _HairStyle.short,
        hasBeard: true,
      ),
    ),
    _AvatarOption(
      label: 'Erkek 2',
      style: _AvatarStyle(
        background: Color(0xFF83C5BE),
        skin: Color(0xFFE0B089),
        hair: Color(0xFF1B1B1B),
        shirt: Color(0xFF2F6F4E),
        hairStyle: _HairStyle.side,
        hasGlasses: true,
      ),
    ),
    _AvatarOption(
      label: 'Erkek 3',
      style: _AvatarStyle(
        background: Color(0xFFF4B183),
        skin: Color(0xFFF0B47A),
        hair: Color(0xFF4A2F1B),
        shirt: Color(0xFF355C7D),
        hairStyle: _HairStyle.short,
      ),
    ),
    _AvatarOption(
      label: 'Erkek 4',
      style: _AvatarStyle(
        background: Color(0xFF7FB3D5),
        skin: Color(0xFFF6D2B8),
        hair: Color(0xFFB57E4A),
        shirt: Color(0xFF7A3B3B),
        hairStyle: _HairStyle.short,
      ),
    ),
    _AvatarOption(
      label: 'Kiz 1',
      style: _AvatarStyle(
        background: Color(0xFFFFB4A2),
        skin: Color(0xFFF2C7A8),
        hair: Color(0xFFB45A2B),
        shirt: Color(0xFFB23A48),
        hairStyle: _HairStyle.long,
      ),
    ),
    _AvatarOption(
      label: 'Kiz 2',
      style: _AvatarStyle(
        background: Color(0xFFFAD2A8),
        skin: Color(0xFFF3C39E),
        hair: Color(0xFF3D2A1C),
        shirt: Color(0xFF2A9D8F),
        hairStyle: _HairStyle.bun,
      ),
    ),
    _AvatarOption(
      label: 'Kiz 3',
      style: _AvatarStyle(
        background: Color(0xFFB8E1DD),
        skin: Color(0xFFF0BFA1),
        hair: Color(0xFF1F1B24),
        shirt: Color(0xFFF4C95D),
        hairStyle: _HairStyle.long,
        hasGlasses: true,
      ),
    ),
    _AvatarOption(
      label: 'Kiz 4',
      style: _AvatarStyle(
        background: Color(0xFFE9CBA7),
        skin: Color(0xFFF4C7B4),
        hair: Color(0xFF5A3B2E),
        shirt: Color(0xFFD96C8A),
        hairStyle: _HairStyle.side,
      ),
    ),
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _statusController;
  int _selectedAvatarIndex = 0;
  bool _saved = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'UB Kullanici');
    _statusController = TextEditingController(text: 'Profilini ozellestir.');
    _nameController.addListener(_onFormChanged);
    _statusController.addListener(_onFormChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _statusController.removeListener(_onFormChanged);
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (_saved) {
      setState(() {
        _saved = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data();
      if (data == null || !mounted) {
        return;
      }

      final name = data['name'];
      final status = data['status'];
      final avatarIndex = data['avatarIndex'];

      setState(() {
        if (name is String && name.trim().isNotEmpty) {
          _nameController.text = name;
        }
        if (status is String && status.trim().isNotEmpty) {
          _statusController.text = status;
        }
        if (avatarIndex is int &&
            avatarIndex >= 0 &&
            avatarIndex < _avatarOptions.length) {
          _selectedAvatarIndex = avatarIndex;
        }
        _saved = true;
      });
    } catch (_) {
      // Ignore read errors here; UI still works with defaults.
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giris yapilmadi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': _nameController.text.trim(),
          'status': _statusController.text.trim(),
          'avatarIndex': _selectedAvatarIndex,
        },
        SetOptions(merge: true),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil kaydedildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kaydetme basarisiz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedAvatar = _avatarOptions[_selectedAvatarIndex];
    return Scaffold(
      body: Stack(
        children: [
          const SimpleBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsHeader(
                    title: 'Profil',
                    subtitle: 'Gorunurluk ve profil bilgileri.',
                    showBack: true,
                  ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  child: Row(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              withOpacity(kSun, 0.95),
                              withOpacity(kCoral, 0.8),
                            ],
                          ),
                        ),
                        child: _AvatarIcon(
                          style: selectedAvatar.style,
                          size: 52,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusController.text,
                              style: textTheme.bodyMedium?.copyWith(
                                color: withOpacity(kMidnight, 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil fotografi',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gercek fotograf yerine bir ikon sec.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: withOpacity(kMidnight, 0.65),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(
                          _avatarOptions.length,
                          (index) {
                            final option = _avatarOptions[index];
                            final isSelected =
                                index == _selectedAvatarIndex;
                            return Semantics(
                              button: true,
                              selected: isSelected,
                              label: option.label,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    _selectedAvatarIndex = index;
                                    _saved = false;
                                  });
                                },
                                child: Container(
                                  width: 72,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? withOpacity(kSun, 0.15)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? kSun
                                          : withOpacity(kMidnight, 0.2),
                                      width: isSelected ? 1.6 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _AvatarIcon(
                                        style: option.style,
                                        size: 36,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        option.label,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: withOpacity(kMidnight, 0.7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hakkinda',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Ad soyad',
                          hintStyle:
                              TextStyle(color: withOpacity(kMidnight, 0.45)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: withOpacity(kCoral, 0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: withOpacity(kCoral, 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: kSun,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _statusController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Kisa bir durum yazisi ekle.',
                          hintStyle:
                              TextStyle(color: withOpacity(kMidnight, 0.45)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: withOpacity(kCoral, 0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: withOpacity(kCoral, 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: kSun,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saved ? null : _saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: kSun,
                            foregroundColor: kMidnight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.save),
                          label: Text(_saved ? 'Kaydedildi' : 'Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gorunurluk',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Profil kartini sadece eslestigin kisiler gorebilir.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: withOpacity(kMidnight, 0.65),
                        ),
                      ),
                    ],
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

class _AvatarOption {
  const _AvatarOption({required this.label, required this.style});

  final String label;
  final _AvatarStyle style;
}

enum _HairStyle { short, side, long, bun }

class _AvatarStyle {
  const _AvatarStyle({
    required this.background,
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.hairStyle,
    this.hasBeard = false,
    this.hasGlasses = false,
  });

  final Color background;
  final Color skin;
  final Color hair;
  final Color shirt;
  final _HairStyle hairStyle;
  final bool hasBeard;
  final bool hasGlasses;
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({required this.style, required this.size});

  final _AvatarStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AvatarPainter(style),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.style);

  final _AvatarStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final backgroundPaint = Paint()..color = style.background;
    final hairPaint = Paint()..color = style.hair;
    final skinPaint = Paint()..color = style.skin;
    final shirtPaint = Paint()..color = style.shirt;

    canvas.drawCircle(center, size.width / 2, backgroundPaint);

    final headCenter = Offset(center.dx, center.dy - size.height * 0.06);
    final headRadius = size.width * 0.22;

    switch (style.hairStyle) {
      case _HairStyle.short:
        canvas.drawCircle(
          Offset(headCenter.dx, headCenter.dy - size.height * 0.06),
          headRadius * 1.35,
          hairPaint,
        );
        break;
      case _HairStyle.side:
        canvas.drawCircle(
          Offset(headCenter.dx, headCenter.dy - size.height * 0.08),
          headRadius * 1.4,
          hairPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                headCenter.dx + headRadius * 0.9,
                headCenter.dy + headRadius * 0.35,
              ),
              width: headRadius * 0.55,
              height: headRadius * 1.4,
            ),
            const Radius.circular(12),
          ),
          hairPaint,
        );
        break;
      case _HairStyle.long:
        canvas.drawCircle(
          Offset(headCenter.dx, headCenter.dy - size.height * 0.08),
          headRadius * 1.5,
          hairPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                headCenter.dx - headRadius * 0.9,
                headCenter.dy + headRadius * 0.75,
              ),
              width: headRadius * 0.7,
              height: headRadius * 2.2,
            ),
            const Radius.circular(16),
          ),
          hairPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                headCenter.dx + headRadius * 0.9,
                headCenter.dy + headRadius * 0.75,
              ),
              width: headRadius * 0.7,
              height: headRadius * 2.2,
            ),
            const Radius.circular(16),
          ),
          hairPaint,
        );
        break;
      case _HairStyle.bun:
        canvas.drawCircle(
          Offset(headCenter.dx, headCenter.dy - size.height * 0.12),
          headRadius * 0.65,
          hairPaint,
        );
        canvas.drawCircle(
          Offset(headCenter.dx, headCenter.dy - size.height * 0.24),
          headRadius * 0.4,
          hairPaint,
        );
        break;
    }

    canvas.drawCircle(headCenter, headRadius, skinPaint);

    final eyeOffset = headRadius * 0.45;
    final eyeRadius = headRadius * 0.12;
    canvas.drawCircle(
      Offset(headCenter.dx - eyeOffset, headCenter.dy - headRadius * 0.1),
      eyeRadius,
      Paint()..color = kMidnight,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + eyeOffset, headCenter.dy - headRadius * 0.1),
      eyeRadius,
      Paint()..color = kMidnight,
    );

    if (style.hasGlasses) {
      final glassesPaint = Paint()
        ..color = kMidnight
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.03;
      final glassSize = headRadius * 0.7;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(headCenter.dx - eyeOffset, headCenter.dy - 2),
            width: glassSize,
            height: glassSize * 0.65,
          ),
          const Radius.circular(6),
        ),
        glassesPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(headCenter.dx + eyeOffset, headCenter.dy - 2),
            width: glassSize,
            height: glassSize * 0.65,
          ),
          const Radius.circular(6),
        ),
        glassesPaint,
      );
      canvas.drawLine(
        Offset(headCenter.dx - eyeOffset + glassSize * 0.5, headCenter.dy - 2),
        Offset(headCenter.dx + eyeOffset - glassSize * 0.5, headCenter.dy - 2),
        glassesPaint,
      );
    }

    final mouthRect = Rect.fromCenter(
      center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.55),
      width: headRadius * 0.9,
      height: headRadius * 0.5,
    );
    canvas.drawArc(
      mouthRect,
      0,
      3.14,
      false,
      Paint()
        ..color = kMidnight
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04,
    );

    if (style.hasBeard) {
      final beardRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.75),
        width: headRadius * 1.3,
        height: headRadius * 0.8,
      );
      canvas.drawArc(
        beardRect,
        0,
        3.14,
        false,
        Paint()
          ..color = style.hair
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.06,
      );
    }

    final torsoRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size.height * 0.3),
      width: size.width * 0.6,
      height: size.height * 0.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(torsoRect, const Radius.circular(20)),
      shirtPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}
