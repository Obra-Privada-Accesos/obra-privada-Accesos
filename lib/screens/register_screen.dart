import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Campos
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptedPrivacy = false;
  bool _isLoading = false;

  // Rol por defecto (ya no se elige en UI)
  final String _role = 'Empleado';

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAcceptance();
  }

  Future<void> _loadAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _acceptedPrivacy = prefs.getBool('accepted_privacy') ?? false;
    });
  }

  Future<void> _saveAcceptance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_privacy', value);
  }

  // ---------- Reglas de contraseña fuerte ----------
  bool _isStrongPassword(String s) {
    if (s.length < 8) return false;

    final hasUpper = s.contains(RegExp(r'[A-Z]'));
    final hasDigit = s.contains(RegExp(r'[0-9]'));
    final hasSpecial = s.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));

    return hasUpper && hasDigit && hasSpecial;
  }

  // ============ REGISTRO CON FIREBASE ============
  Future<void> _register() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar el aviso de privacidad para registrarte.',
          ),
        ),
      );
      return;
    }

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final fullName = '$firstName $lastName';
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // 🔒 Doble check por si algo raro pasa con el form
    if (!_isStrongPassword(pass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La contraseña debe tener mínimo 8 caracteres, '
            'con al menos 1 mayúscula, 1 número y 1 carácter especial.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) Crear usuario en Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'No se pudo crear el usuario.',
        );
      }

      // 2) Guardar datos en Firestore (colección "users")
      await _db.collection('users').doc(user.uid).set({
        'nombre': firstName,
        'apellidos': lastName,
        'nombreCompleto': fullName,
        'correo': email,
        'role': _role, // siempre Empleado
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3) Enviar correo de verificación
      await user.sendEmailVerification();

      // 4) Guardar algunos datos localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);
      await prefs.setString('user_name', fullName);
      await prefs.setString('user_email', email);
      await prefs.setString('user_role', _role);
      await _saveAcceptance(_acceptedPrivacy);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registro exitoso. Te enviamos un correo de verificación a $email.\n'
            'Revisa tu bandeja y confirma tu correo antes de iniciar sesión.',
          ),
        ),
      );
      Navigator.pop(context); // vuelve al login
    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 FIREBASE AUTH ERROR: ${e.code} - ${e.message}');

      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Este correo ya está registrado.';
          break;
        case 'weak-password':
          msg = 'La contraseña es demasiado débil (mínimo 8 caracteres).';
          break;
        case 'invalid-email':
          msg = 'El correo no es válido.';
          break;
        case 'operation-not-allowed':
          msg =
              'El método Email/Password no está habilitado en Firebase.\nActívalo en Authentication > Sign-in method.';
          break;
        case 'network-request-failed':
          msg =
              'No se pudo conectar con el servidor. Revisa tu conexión a internet.';
          break;
        default:
          msg = 'Error (${e.code}): ${e.message ?? 'Intenta más tarde.'}';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      debugPrint('🔥 ERROR GENERAL REGISTER: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final orange = Colors.orange;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF4E6), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Row(
                          children: const [
                            Icon(
                              Icons.person_add_alt_1,
                              color: Colors.orange,
                              size: 26,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Regístrate para usar GeoToolTrack como empleado.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nombre(s)
                        TextFormField(
                          controller: _firstNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nombre(s)',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa tu nombre'
                              : null,
                        ),
                        const SizedBox(height: 10),

                        // Apellidos
                        TextFormField(
                          controller: _lastNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Apellidos',
                            prefixIcon: const Icon(Icons.badge),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa tus apellidos'
                              : null,
                        ),
                        const SizedBox(height: 10),

                        // Correo
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Ingresa tu correo';
                            if (!s.contains('@')) {
                              return 'El correo debe contener @';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Contraseña (con reglas fuertes)
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Contraseña (mínimo 8 caracteres)',
                            helperText:
                                'Debe incluir mayúscula, número y carácter especial.',
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (v) {
                            final s = v ?? '';
                            if (s.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (!_isStrongPassword(s)) {
                              return 'Mínimo 8 caracteres, con 1 mayúscula, 1 número y 1 carácter especial.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Confirmar contraseña
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (v) => (v ?? '') != _passCtrl.text
                              ? 'Las contraseñas no coinciden'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Info de rol
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB3D4FF)),
                          ),
                          child: const Text(
                            'Tu cuenta se registrará con rol: Empleado.\n'
                            'Si necesitas acceso de administrador, el encargado del sistema puede asignártelo después.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1F4E79),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Bloque aviso de privacidad
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptedPrivacy,
                                onChanged: (val) async {
                                  setState(
                                    () => _acceptedPrivacy = val ?? false,
                                  );
                                  await _saveAcceptance(_acceptedPrivacy);
                                },
                                activeColor: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'He leído y acepto el aviso de privacidad.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    // Navega a tu screen de aviso
                                    // (asegúrate de tener la ruta /avisoPrivacidad en main.dart)
                                    _AvisoLink(),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tus datos se usarán únicamente para el acceso al sistema y el control de herramientas, conforme a la LFPDPPP.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Botón Registrarme
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Registrarme',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Volver al login centrado
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Volver a iniciar sesión',
                              style: TextStyle(
                                color: orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoLink extends StatelessWidget {
  const _AvisoLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/avisoPrivacidad');
      },
      child: const Text(
        'Ver aviso de privacidad',
        style: TextStyle(
          color: Colors.orange,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
