import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/main_shell.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasShadow = Color(0x1A121214);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isBusy = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainShell(),
          ),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        setState(() {
          _isLogin = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kayit basarili. Simdi giris yapabilirsiniz.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final details = error.message == null ? '' : ' - ${error.message}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_mapAuthError(error.code)} (${error.code})$details',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-posta adresi gecersiz.';
      case 'user-not-found':
        return 'Kullanici bulunamadi.';
      case 'wrong-password':
        return 'Sifre hatali.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullaniliyor.';
      case 'weak-password':
        return 'Sifre en az 6 karakter olmali.';
      default:
        return 'Islem basarisiz. Tekrar deneyin.';
    }
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'E-posta gerekli.';
    }
    if (!text.contains('@')) {
      return 'E-posta formati hatali.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Sifre gerekli.';
    }
    if (text.length < 6) {
      return 'Sifre en az 6 karakter olmali.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (_isLogin) {
      return null;
    }
    if (value != _passwordController.text) {
      return 'Sifreler eslesmiyor.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF7F2E8),
                    Color(0xFFE9F4F2),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.25,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                color: withOpacity(kSun, 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UB Sohbet',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Tekrar hos geldin. Hemen giris yap.'
                        : 'Yeni bir hesap olustur, sohbetlere katil.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: withOpacity(_atlasShadow, 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AuthSegment(
                              isLogin: _isLogin,
                              onTap: (value) {
                                setState(() {
                                  _isLogin = value;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'E-posta',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              decoration: const InputDecoration(
                                hintText: 'ornek@ubsohbet.com',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sifre',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              validator: _validatePassword,
                              decoration: const InputDecoration(
                                hintText: '********',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Sifre tekrar',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: true,
                                validator: _validateConfirm,
                                decoration: const InputDecoration(
                                  hintText: '********',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isBusy ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _atlasAmber,
                                  foregroundColor: _atlasInk,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isBusy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Giris yap' : 'Kayit ol',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _isBusy
                                    ? null
                                    : () {
                                        setState(() {
                                          _isLogin = !_isLogin;
                                        });
                                      },
                                child: Text(
                                  _isLogin
                                      ? 'Hesabin yok mu? Kayit ol'
                                      : 'Zaten hesabin var mi? Giris yap',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Sohbet odalarina girmek icin hizli ve guvenli giris.',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _AuthSegment extends StatelessWidget {
  const _AuthSegment({
    required this.isLogin,
    required this.onTap,
  });

  final bool isLogin;
  final ValueChanged<bool> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: withOpacity(_atlasTeal, 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Giris',
              isSelected: isLogin,
              onTap: () => onTap(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SegmentButton(
              label: 'Kayit',
              isSelected: !isLogin,
              onTap: () => onTap(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _atlasTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _atlasInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
