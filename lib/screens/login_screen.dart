import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscure = true;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _showNotVerifiedDialog(User user) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verifica tu correo'),
        content: Text(
          'Tu cuenta aún no está verificada.\n\n'
          'Te enviamos un correo cuando te registraste. '
          'Abre el enlace de verificación en el correo de:\n\n${user.email}',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await user.sendEmailVerification();
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Se ha reenviado el correo de verificación.'),
                ),
              );
            },
            child: const Text('Reenviar correo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ---- Login normal ----
  Future<void> _login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'No se pudo obtener el usuario.',
        );
      }

      // Verificación de correo
      if (!user.emailVerified) {
        await _auth.signOut();
        await _showNotVerifiedDialog(user);
        return;
      }

      // Info extra en Firestore
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception(
          'No se encontró el documento del usuario en Firestore.',
        );
      }

      final data = userDoc.data() as Map<String, dynamic>;

      final firstName = (data['nombre'] ?? '') as String;
      final lastName = (data['apellidos'] ?? '') as String;
      final fullName =
          (data['nombreCompleto'] ?? '$firstName $lastName') as String;
      final role = (data['role'] ?? 'Empleado') as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);
      await prefs.setString('user_name', fullName);
      await prefs.setString('user_role', role);

      if (role == 'Administrador' || role.toLowerCase() == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/employee');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error al iniciar sesión';
      if (e.code == 'user-not-found') {
        msg = 'No existe un usuario con ese correo.';
      } else if (e.code == 'wrong-password') {
        msg = 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-email') {
        msg = 'Correo no válido.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
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

  Future<void> _onLoginPressed() async {
    // 🔹 Ya NO bloqueamos por aviso de privacidad, solo iniciamos sesión
    await _login();
  }

  // ---- Login con Google ----
  Future<void> _loginWithGoogle() async {
    // 🔹 Igual, ya no exigimos aviso aquí. Solo login.
    setState(() => _isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        throw Exception('No se pudo obtener el usuario de Google.');
      }

      final email = user.email ?? '';
      final displayName = user.displayName ?? '';
      String firstName = displayName;
      String lastName = '';

      if (displayName.contains(' ')) {
        final parts = displayName.split(' ');
        firstName = parts.first;
        lastName = parts.sublist(1).join(' ');
      }

      final fullName = '$firstName $lastName';

      final userRef = _db.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      String role = 'Empleado';

      if (!userDoc.exists) {
        await userRef.set({
          'nombre': firstName,
          'apellidos': lastName,
          'nombreCompleto': fullName,
          'correo': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        });
      } else {
        final data = userDoc.data() as Map<String, dynamic>;
        role = (data['role'] ?? 'Empleado') as String;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_first_name', firstName);
      await prefs.setString('user_last_name', lastName);
      await prefs.setString('user_name', fullName);
      await prefs.setString('user_role', role);

      if (role == 'Administrador' || role.toLowerCase() == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/employee');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error con Google: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===================== UI BONITA =====================
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;

              final cardChild = isNarrow
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBrandSide(orange, isNarrow),
                        _buildFormSide(orange, isNarrow),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildBrandSide(orange, isNarrow)),
                        Expanded(child: _buildFormSide(orange, isNarrow)),
                      ],
                    );

              return Container(
                margin: const EdgeInsets.all(16),
                constraints: const BoxConstraints(
                  maxWidth: 900,
                  maxHeight: 520,
                ),
                child: Card(
                  elevation: 14,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: cardChild,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSide(Color orange, bool isNarrow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [orange, orange.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: isNarrow
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.handyman, color: Colors.white, size: 30),
              SizedBox(width: 8),
              Text(
                'GeoToolTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Control profesional de herramientas,\n'
            'empleados y registros de préstamos\n'
            'para tu obra privada.',
            textAlign: isNarrow ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Chips que navegan a pantallas informativas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                text: 'Inventario en tiempo real',
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/inventarioInfo');
                },
              ),
              _Tag(
                text: 'Historial de préstamos',
                icon: Icons.history,
                onTap: () {
                  Navigator.pushNamed(context, '/historialInfo');
                },
              ),
              _Tag(
                text: 'Múltiples empleados',
                icon: Icons.group_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/empleadosInfo');
                },
              ),
              _Tag(
                text: 'Proveedores',
                icon: Icons.storefront_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/suppliersInfo');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSide(Color orange, bool isNarrow) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 20 : 32,
        vertical: isNarrow ? 20 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inicia sesión para acceder a tu panel.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),

                  // Correo
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Ingresa tu correo';
                      if (!v.contains('@')) {
                        return 'El correo debe contener @';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) return 'Ingresa tu contraseña';
                      if (v.length < 8) return 'Mínimo 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Iniciar Sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
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
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Botón Google
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Image.asset('assets/google_logo.png', height: 20),
                      label: const Text(
                        'Continuar con Google',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Olvidó contraseña centrado
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgot'),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: orange),
                      ),
                    ),
                  ),

                  // Crear cuenta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Crear cuenta',
                          style: TextStyle(
                            color: orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // 👇 SOLO CONSULTA DEL AVISO DE PRIVACIDAD
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/avisoPrivacidad');
                      },
                      icon: Icon(
                        Icons.privacy_tip_outlined,
                        color: orange,
                        size: 20,
                      ),
                      label: Text(
                        'Ver aviso de privacidad',
                        style: TextStyle(
                          color: orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
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
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const _Tag({required this.text, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: content,
      ),
    );
  }
}
