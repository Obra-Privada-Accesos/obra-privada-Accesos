import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; //  kIsWeb
import 'package:flutter/material.dart';
// Imports Clima principales
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

// si no lo usas, lo puedes borrar
import 'screens/admin_screen.dart';
import 'screens/aviso_privacidad.dart';
import 'screens/clima_screen.dart';
import 'screens/empleados.dart';
import 'screens/employe_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/historial.dart';
// Screens informativas
import 'screens/inventario.dart';
// Screens principales
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/suppliers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Estilo de barra de estado (opcional)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
  );

  // Inicializar formatos de fecha en español (para Clima)
  await initializeDateFormatting('es_MX', null);

  // Cargar variables de entorno (.env) para la API del clima
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error cargando .env: $e");
  }

  if (kIsWeb) {
    // 🔥 CONFIG DE LA WEB (la que te dio Firebase en el snippet JS)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "tu api key de firebase",
        authDomain: "tu auth domain de firebase",
        projectId: "tu project id de firebase",
        storageBucket: "tu storage bucket de firebase",
        messagingSenderId: "tu messaging sender id de firebase",
        appId: "tu app id de firebase",
      ),
    );
  } else {
    // 📱 ANDROID / iOS -> usan google-services.json / plist como siempre
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoToolTrack',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',

      // Rutas "directas"
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),

        // Pantalla del clima (Inicio del admin)
        '/clima': (context) => const ClimaScreen(),

        // Pantallas informativas
        '/inventarioInfo': (context) => const InventarioInfoScreen(),
        '/historialInfo': (context) => const HistorialInfoScreen(),
        '/empleadosInfo': (context) => const EmpleadosInfoScreen(),
        '/suppliersInfo': (context) => const SuppliersInfoScreen(),

        // Aviso de privacidad dentro de la app
        '/avisoPrivacidad': (context) => const AvisoPrivacidadScreen(),
      },

      // Aquí controlamos quién puede entrar a /admin y /employee
      onGenerateRoute: (settings) {
        final user = FirebaseAuth.instance.currentUser;

        MaterialPageRoute goLogin() {
          return MaterialPageRoute(builder: (_) => LoginScreen());
        }

        // ------- RUTA ADMIN -------
        if (settings.name == '/admin') {
          if (user == null) {
            return goLogin();
          }
          return MaterialPageRoute(builder: (_) => const AdminScreen());
        }

        // ------- RUTA EMPLEADO -------
        if (settings.name == '/employee') {
          if (user == null) {
            return goLogin();
          }
          return MaterialPageRoute(builder: (_) => const EmployeeScreen());
        }

        // Cualquier otra ruta que no exista
        return null;
      },

      // Si ponen una ruta rarísima en la URL
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => LoginScreen());
      },

      // Tema general (no toco colores fuertes para no romper tus UIs)
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFEFAF6),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
