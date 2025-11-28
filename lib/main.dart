<<<<<<< HEAD
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

=======
import 'package:flutter/material.dart';

void main() {
>>>>>>> fae0d21e6a4cf929f087b2db595d9fa61b8c55ea
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

<<<<<<< HEAD
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
=======
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
>>>>>>> fae0d21e6a4cf929f087b2db595d9fa61b8c55ea
    );
  }
}
