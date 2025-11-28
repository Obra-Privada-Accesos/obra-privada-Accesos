// admin_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:obraprivada/widgets/chatbot_fab.dart';
import 'package:url_launcher/url_launcher.dart';

// ===== Enum de secciones del Admin =====
enum AdminSection {
  inicio, // Clima
  clientes,
  projects,
  suppliers,
  orders,
  warehouse,
  registros,
  reports,
  incidentes,
  consultas,
  empleados,
}

// Lista de roles/puestos disponibles
const List<String> kEmployeeRoles = [
  'Albañil',
  'Carpintero',
  'Fierrero / Armador',
  'Operador de Maquinaria Pesada',
  'Electricista',
  'Plomero / Fontanero',
  'Maestro de Obra',
  'Residente de Obra',
  'Topógrafo',
  'Pintor / Yesero',
  'Admin', // Este rol dará privilegios de administrador
];

// ===== Estados de la vista de Clima =====
enum ViewState { idle, loading, success, error }

// Helper para capitalizar
String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ==== Helper para pedidos en lote ====
class _OrderDraftLine {
  final String supplierId;
  final String supplierName;
  final String supplierEmail;
  final String product;
  final int quantity;
  final String priority;

  _OrderDraftLine({
    required this.supplierId,
    required this.supplierName,
    required this.supplierEmail,
    required this.product,
    required this.quantity,
    required this.priority,
  });
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Color brandOrange = const Color(0xFFD76728);
  final Color panelBg = const Color(0xFFFFF4EB);
  final Color pageBg = const Color(0xFFFEFAF6);

  AdminSection _selected = AdminSection.inicio;
  bool _isMenuCollapsed = false;

  // 🔥 Firestore
  final _db = FirebaseFirestore.instance;
  late final CollectionReference _clientsRef;
  late final CollectionReference _toolsRef;
  late final CollectionReference _loansRef;
  late final CollectionReference _requestsRef;
  late final CollectionReference _suppliersRef;
  late final CollectionReference _usersRef;
  late final CollectionReference _ordersRef;
  late final CollectionReference _reportsRef;
  late final CollectionReference _warehouseRef;
  late final CollectionReference _projectsRef;
  late final CollectionReference _activitiesRef;
  late final CollectionReference _warehouseRequestsRef;
  late final CollectionReference _incidentsRef;

  // Clientes
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  // Filtro de clientes
  final TextEditingController _clientSearchCtrl = TextEditingController();
  String _clientFilter = '';

  // Herramientas
  final _herrCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  // Proveedores
  final _supNombreContactoCtrl = TextEditingController();
  final _supEmpresaCtrl = TextEditingController();
  final _supProductoCtrl = TextEditingController();
  final _supCorreoCtrl = TextEditingController();
  final _supTelefonoCtrl = TextEditingController();

  // -------- CLIMA (Inicio dentro de Admin) --------
  final TextEditingController _cityWeatherCtrl = TextEditingController();
  ViewState _weatherState = ViewState.idle;
  String _weatherErrorMessage = '';
  Map<String, dynamic>? _weatherData;

  // ===== CONSULTAS =====
  final TextEditingController _consultaCtrl = TextEditingController();
  String _consultaTipo = 'cliente'; // cliente, empleado, herramienta, prestamo
  Map<String, dynamic>? _consultaData;
  String? _consultaError;
  bool _consultaLoading = false;

  // ===== PEDIDOS A PROVEEDORES =====
  final TextEditingController _orderProductCtrl = TextEditingController();
  final TextEditingController _orderQtyCtrl = TextEditingController();
  String _orderPriority = 'Media';
  String? _selectedSupplierForOrderId;
  final List<_OrderDraftLine> _orderDraftLines = [];

  // ===== ALMACÉN =====
  final TextEditingController _whProductCtrl = TextEditingController();
  final TextEditingController _whQtyCtrl = TextEditingController();
  final TextEditingController _whLocationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clientsRef = _db.collection('clients');
    _toolsRef = _db.collection('tools');
    _loansRef = _db.collection('loans');
    _requestsRef = _db.collection('requests');
    _suppliersRef = _db.collection('suppliers');
    _usersRef = _db.collection('users');
    _ordersRef = _db.collection('orders');
    _reportsRef = _db.collection('reports');
    _warehouseRef = _db.collection('warehouse');
    _projectsRef = _db.collection('projects');
    _activitiesRef = _db.collection('activities');
    _warehouseRequestsRef = _db.collection('warehouseRequests');
    _incidentsRef = _db.collection('incidentes');
  }

  // =================== HELPERS DE FECHAS ===================

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate();
    return '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year} '
        '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
  }

  String _formatDateString(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year} '
        '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
  }

  // Solo fecha dd/MM/yyyy desde Timestamp
  String _formatDateOnly(Timestamp? ts) {
    if (ts == null) return 'Sin fecha';
    final dt = ts.toDate();
    return '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year}';
  }

  // Solo fecha dd/MM/yyyy desde String ISO
  String _formatDateOnlyFromString(String raw) {
    if (raw.isEmpty) return 'Sin fecha';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year}';
  }

  // Solo hora HH:mm desde Timestamp
  String _formatHourFromTimestamp(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate();
    return '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
  }

  // Solo hora HH:mm desde String ISO
  String _formatHourFromString(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '—';
    return '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
  }

  // =================== LÓGICA CLIMA ===================

  bool _isValidCity(String input) {
    if (input.isEmpty) return false;
    // Soporta acentos, ñ, espacios, coma, punto y guion
    final validCharacters = RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ\s,.\-]+$');
    return validCharacters.hasMatch(input);
  }

  Future<void> _fetchWeather() async {
    final city = _cityWeatherCtrl.text.trim();

    if (!_isValidCity(city)) {
      setState(() {
        _weatherState = ViewState.error;
        _weatherErrorMessage =
            "Por favor ingresa una ciudad válida (solo letras).";
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _weatherState = ViewState.loading;
      _weatherErrorMessage = '';
    });

    try {
      final apiKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception("API Key no configurada en .env");
      }

      final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'q': city,
        'appid': apiKey,
        'units': 'metric',
        'lang': 'es',
      });

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException("La petición tardó demasiado."),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = data;
          _weatherState = ViewState.success;
        });
      } else if (response.statusCode == 404) {
        throw Exception("Ciudad no encontrada. Verifica el nombre.");
      } else if (response.statusCode == 401) {
        throw Exception("Error de autenticación (API Key inválida).");
      } else if (response.statusCode == 429) {
        throw Exception("Demasiadas peticiones. Intenta más tarde.");
      } else {
        throw Exception("Error del servidor: ${response.statusCode}");
      }
    } on SocketException {
      setState(() {
        _weatherState = ViewState.error;
        _weatherErrorMessage = "No hay conexión a internet.";
      });
    } on TimeoutException {
      setState(() {
        _weatherState = ViewState.error;
        _weatherErrorMessage = "El servidor tardó mucho en responder.";
      });
    } catch (e) {
      setState(() {
        _weatherState = ViewState.error;
        _weatherErrorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  // =================== LÓGICA CONSULTAS ===================

  Future<void> _consultarPorId() async {
    final id = _consultaCtrl.text.trim();
    if (id.isEmpty) {
      setState(() {
        _consultaError = "Ingresa un ID";
        _consultaData = null;
      });
      return;
    }

    setState(() {
      _consultaLoading = true;
      _consultaError = null;
      _consultaData = null;
    });

    try {
      DocumentSnapshot doc;
      if (_consultaTipo == 'cliente') {
        doc = await _clientsRef.doc(id).get();
      } else if (_consultaTipo == 'empleado') {
        doc = await _usersRef.doc(id).get();
      } else if (_consultaTipo == 'herramienta') {
        doc = await _toolsRef.doc(id).get();
      } else {
        // prestamo
        doc = await _loansRef.doc(id).get();
      }

      if (!doc.exists) {
        setState(() {
          _consultaError = "No se encontró ningún registro con ese ID.";
          _consultaData = null;
        });
      } else {
        setState(() {
          _consultaData = doc.data() as Map<String, dynamic>;
          _consultaError = null;
        });
      }
    } catch (e) {
      setState(() {
        _consultaError = "Error al consultar: $e";
        _consultaData = null;
      });
    } finally {
      setState(() {
        _consultaLoading = false;
      });
    }
  }

  // =================== BUILD ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: Icon(
                _isMenuCollapsed ? Icons.menu : Icons.menu_open,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _isMenuCollapsed = !_isMenuCollapsed);
              },
            ),
            const SizedBox(width: 4),
            const Text(
              "GeoToolTrack",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              icon: const Icon(Icons.logout, color: Colors.white, size: 18),
              label: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: const ChatbotFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              color: pageBg,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: _buildSection(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final collapsed = _isMenuCollapsed;
    final double width = collapsed ? 68 : 220;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(right: BorderSide(color: Colors.black12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: collapsed
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _SideItem(
                icon: Icons.cloud_outlined,
                label: "Clima",
                compact: collapsed,
                selected: _selected == AdminSection.inicio,
                onTap: () => setState(() => _selected = AdminSection.inicio),
              ),
              _SideItem(
                icon: Icons.people_alt_outlined,
                label: "Clientes",
                compact: collapsed,
                selected: _selected == AdminSection.clientes,
                onTap: () => setState(() => _selected = AdminSection.clientes),
              ),
              _SideItem(
                icon: Icons.home_work_outlined,
                label: "Proyectos",
                compact: collapsed,
                selected: _selected == AdminSection.projects,
                onTap: () => setState(() => _selected = AdminSection.projects),
              ),

              _SideItem(
                icon: Icons.storefront_outlined,
                label: "Proveedores",
                compact: collapsed,
                selected: _selected == AdminSection.suppliers,
                onTap: () => setState(() => _selected = AdminSection.suppliers),
              ),
              _SideItem(
                icon: Icons.local_shipping_outlined,
                label: "Pedidos",
                compact: collapsed,
                selected: _selected == AdminSection.orders,
                onTap: () => setState(() => _selected = AdminSection.orders),
              ),
              _SideItem(
                icon: Icons.inventory_2_outlined,
                label: "Almacén",
                compact: collapsed,
                selected: _selected == AdminSection.warehouse,
                onTap: () => setState(() => _selected = AdminSection.warehouse),
              ),

              // Registros con badge de solicitudes pendientes
              StreamBuilder<QuerySnapshot>(
                stream: _requestsRef
                    .where('status', isEqualTo: 'pendiente')
                    .snapshots(),
                builder: (context, snapshot) {
                  int pendingCount = 0;
                  if (snapshot.hasData) {
                    pendingCount = snapshot.data!.docs.length;
                  }
                  return _SideItem(
                    icon: Icons.assignment_turned_in_outlined,
                    label: "Registros",
                    compact: collapsed,
                    selected: _selected == AdminSection.registros,
                    onTap: () =>
                        setState(() => _selected = AdminSection.registros),
                    badge: pendingCount,
                  );
                },
              ),

              _SideItem(
                icon: Icons.report_problem_outlined,
                label: "Reportes",
                compact: collapsed,
                selected: _selected == AdminSection.reports,
                onTap: () => setState(() => _selected = AdminSection.reports),
              ),
              _SideItem(
                icon: Icons.health_and_safety,
                label: "Incidentes",
                compact: collapsed,
                selected: _selected == AdminSection.incidentes,
                onTap: () =>
                    setState(() => _selected = AdminSection.incidentes),
              ),
              _SideItem(
                icon: Icons.search,
                label: "Consultas",
                compact: collapsed,
                selected: _selected == AdminSection.consultas,
                onTap: () => setState(() => _selected = AdminSection.consultas),
              ),
              _SideItem(
                icon: Icons.badge_outlined,
                label: "Empleados",
                compact: collapsed,
                selected: _selected == AdminSection.empleados,
                onTap: () => setState(() => _selected = AdminSection.empleados),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Helper para el chip de estado
  Widget _StatusPill({
    required String text,
    required Color bg,
    required Color border,
    required Color textColor,
  }) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  // 🔹 Helper para mostrar true/false con ícono
  Widget _boolIcon(bool value) {
    return Icon(
      value ? Icons.check_circle_outline : Icons.cancel_outlined,
      size: 18,
      color: value ? Colors.green : Colors.redAccent,
    );
  }

  Widget _buildSection() {
    switch (_selected) {
      case AdminSection.inicio:
        return _buildClimaSection();
      case AdminSection.clientes:
        return _buildClientesSection();
      case AdminSection.suppliers:
        return _buildSuppliersSection();
      case AdminSection.orders:
        return _buildOrdersSection();
      case AdminSection.warehouse:
        return _buildWarehouseSection();
      case AdminSection.projects:
        return _buildProjectsSection();
      // case AdminSection.herramientas:
      //return _buildHerramientasSection();
      case AdminSection.registros:
        return _buildRegistrosSection();
      case AdminSection.reports:
        return _buildReportsSection();
      case AdminSection.consultas:
        return _buildConsultasSection();
      case AdminSection.empleados:
        return _buildEmpleadosSection();
      case AdminSection.incidentes:
        return _buildIncidentesSection();
    }
  }

  // =================== SECCIÓN CLIMA ===================

  Widget _buildClimaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Panel de administración", color: brandOrange),
        const SizedBox(height: 10),
        const Text(
          "Consulta el clima en obra para planear jornadas, uso de EPP y prevención de accidentes.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Container(
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3D9C8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.cloud_outlined,
                        color: Color(0xFFD76728),
                        size: 26,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Clima en tiempo real",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ingresa una ciudad para ver la temperatura, humedad y viento actual.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  _buildWeatherSearchBar(),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildWeatherDynamicContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherSearchBar() {
    return TextField(
      controller: _cityWeatherCtrl,
      decoration: const InputDecoration(
        hintText: 'Ingresa una ciudad (ej: Querétaro, MX)',
        suffixIcon: Icon(Icons.search),
      ),
      onSubmitted: (_) => _fetchWeather(),
    );
  }

  Widget _buildWeatherDynamicContent() {
    switch (_weatherState) {
      case ViewState.loading:
        return const Padding(
          key: ValueKey('w_loading'),
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFD76728)),
          ),
        );
      case ViewState.error:
        return _buildWeatherErrorState();
      case ViewState.success:
        return _buildWeatherSuccessState();
      case ViewState.idle:
      default:
        return const Padding(
          key: ValueKey('w_idle'),
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            "Escribe una ciudad y presiona Enter o el ícono de búsqueda.",
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        );
    }
  }

  Widget _buildWeatherErrorState() {
    return Container(
      key: const ValueKey('w_error'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Algo salió mal",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weatherErrorMessage,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _fetchWeather,
                    child: const Text(
                      "Reintentar",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSuccessState() {
    if (_weatherData == null) return _buildWeatherErrorState();

    final main = _weatherData!['main'];
    final weather = _weatherData!['weather'][0];
    final wind = _weatherData!['wind'];

    final temp = main['temp'].toStringAsFixed(0);
    final feelsLike = main['feels_like'].toStringAsFixed(1);
    final humidity = main['humidity'].toString();
    final windSpeed = wind['speed'].toString();
    final description = weather['description'].toString();
    final city = _weatherData!['name'];
    final country = _weatherData!['sys']['country'];

    final iconCode = weather['icon'];
    final iconUrl = 'https://openweathermap.org/img/wn/$iconCode@4x.png';

    final timezoneOffset = _weatherData!['timezone'] as int;
    final localTime = DateTime.now().toUtc().add(
      Duration(seconds: timezoneOffset),
    );

    final formattedDate = capitalize(
      DateFormat.yMMMMEEEEd('es_MX').format(localTime),
    );
    final formattedTime = DateFormat.jm('es_MX').format(localTime);

    return Container(
      key: const ValueKey('w_success'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3D9C8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LADO IZQUIERDO
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  "$city, $country",
                  style: const TextStyle(
                    color: Color(0xFFD76728),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.network(
                      iconUrl,
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.cloud_outlined,
                          size: 70,
                          color: Colors.grey,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        capitalize(description),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // LADO DERECHO
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$temp°",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _weatherItemExtra(
                      Icons.water_drop_outlined,
                      "$humidity%",
                      "Humedad",
                    ),
                    _weatherItemExtra(Icons.air, "${windSpeed}m/s", "Viento"),
                    _weatherItemExtra(
                      Icons.thermostat,
                      "$feelsLike°",
                      "Sensación",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherItemExtra(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFD76728), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }

  // =================== CLIENTES ===================

  Widget _buildClientesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Gestión de Clientes", color: brandOrange),
        const SizedBox(height: 16),
        _PanelCard(
          bg: panelBg,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Input(_nombreCtrl, hint: "Nombre del responsable", width: 220),
              _Input(_correoCtrl, hint: "Correo", width: 220),
              _Input(_telCtrl, hint: "Teléfono", width: 150),
              _Btn(label: "Agregar", color: brandOrange, onTap: _addCliente),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 🔎 Buscador de clientes
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 260,
            child: TextField(
              controller: _clientSearchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar cliente por nombre/correo...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _clientFilter = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        _TableHeader(
          color: brandOrange,
          titles: const ["Nombre", "Correo", "Teléfono", "Acciones"],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _clientsRef.orderBy('nombre').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar clientes: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Sin clientes registrados."),
              );
            }

            final allDocs = snapshot.data!.docs;
            final filteredDocs = allDocs.where((doc) {
              if (_clientFilter.isEmpty) return true;
              final data = doc.data() as Map<String, dynamic>;
              final nombre = (data["nombre"] ?? "").toString().toLowerCase();
              final correo = (data["correo"] ?? "").toString().toLowerCase();
              return nombre.contains(_clientFilter) ||
                  correo.contains(_clientFilter);
            }).toList();

            if (filteredDocs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No se encontraron clientes con ese criterio."),
              );
            }

            return Column(
              children: filteredDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _Row(
                  cells: [
                    Text(data["nombre"] ?? ""),
                    Text(data["correo"] ?? ""),
                    Text(data["tel"] ?? ""),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Actividades',
                          onPressed: () => _openClientActivitiesDialog(doc),
                          icon: const Icon(Icons.event_note),
                          color: Colors.blueGrey,
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _editCliente(doc),
                          icon: const Icon(Icons.edit),
                          color: brandOrange,
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => doc.reference.delete(),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
  // =================== PROYECTOS / OBRAS ===================

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Proyectos / Obras", color: brandOrange),
        const SizedBox(height: 16),
        const Text(
          "Vista de obras ligadas a tus clientes: ubicación, estado y avance.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 18),

        // HEADER TABLA
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Obra",
            "Cliente",
            "Ubicación",
            "Estado",
            "% avance",
            "Acciones",
          ],
          flexes: const [3, 3, 3, 2, 2, 2],
        ),

        // BODY
        StreamBuilder<QuerySnapshot>(
          stream: _projectsRef
              .orderBy('startDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar proyectos: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay proyectos registrados."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final String name = (data['name'] ?? '') as String;
                final String clientName =
                    (data['clientName'] ?? '') as String; // opcional
                final String address = (data['address'] ?? '') as String;
                final String status =
                    (data['status'] ?? 'planeacion') as String;

                DateTime? startDate;
                if (data['startDate'] != null &&
                    data['startDate'] is Timestamp) {
                  startDate = (data['startDate'] as Timestamp).toDate();
                }

                final String location = address.isNotEmpty ? address : '—';

                final int progress = _projectStatusToProgress(status);

                Color bg;
                Color border;
                Color textColor;
                switch (status) {
                  case 'terminada':
                    bg = const Color(0xFFE9F7EF);
                    border = const Color(0xFF27AE60);
                    textColor = const Color(0xFF1E8449);
                    break;
                  case 'en_curso':
                    bg = const Color(0xFFE8F4FD);
                    border = const Color(0xFF1E88E5);
                    textColor = const Color(0xFF1565C0);
                    break;
                  default: // planeacion
                    bg = const Color(0xFFFFF9E6);
                    border = const Color(0xFFF1C40F);
                    textColor = const Color(0xFF7D6608);
                }

                return _Row(
                  flexes: const [3, 3, 3, 2, 2, 2],
                  cells: [
                    // Obra
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (startDate != null)
                          Text(
                            "Inicio: ${startDate.toLocal().toString().substring(0, 10)}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),

                    // Cliente
                    Text(
                      clientName.isEmpty ? '—' : clientName,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Ubicación
                    Text(location, overflow: TextOverflow.ellipsis),

                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        _projectStatusLabel(status),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // % avance
                    Text(
                      "$progress%",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),

                    // Acciones
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SmallBtn(
                        label: "Ver detalle",
                        color: brandOrange,
                        onTap: () => _openProjectDetailDialog(doc.id, data),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // helper de progreso simple
  int _projectStatusToProgress(String status) {
    switch (status) {
      case 'planeacion':
        return 20;
      case 'en_curso':
        return 60;
      case 'terminada':
        return 100;
      default:
        return 0;
    }
  }

  String _projectStatusLabel(String status) {
    switch (status) {
      case 'planeacion':
        return 'Planeación';
      case 'en_curso':
        return 'En curso';
      case 'terminada':
        return 'Terminada';
      default:
        return status;
    }
  }

  void _openProjectDetailDialog(String projectId, Map<String, dynamic> data) {
    final String name = (data['name'] ?? '') as String;
    final String clientName = (data['clientName'] ?? '') as String;
    final String address = (data['address'] ?? '') as String;
    final String status = (data['status'] ?? 'planeacion') as String;

    final Timestamp? startTs = data['startDate'] as Timestamp?;
    final Timestamp? endTs = data['endDate'] as Timestamp?;
    final Timestamp? createdTs = data['createdAt'] as Timestamp?;

    final DateTime? startDate = startTs?.toDate();
    final DateTime? endDate = endTs?.toDate();
    final DateTime? createdAt = createdTs?.toDate();

    final int progress = _projectStatusToProgress(status);
    final String statusLabel = _projectStatusLabel(status);

    // Colores del status (los mismos que en la tabla)
    Color bg;
    Color border;
    Color textColor;
    switch (status) {
      case 'terminada':
        bg = const Color(0xFFE9F7EF);
        border = const Color(0xFF27AE60);
        textColor = const Color(0xFF1E8449);
        break;
      case 'en_curso':
        bg = const Color(0xFFE8F4FD);
        border = const Color(0xFF1E88E5);
        textColor = const Color(0xFF1565C0);
        break;
      default: // planeacion
        bg = const Color(0xFFFFF9E6);
        border = const Color(0xFFF1C40F);
        textColor = const Color(0xFF7D6608);
    }

    String _fmtDate(DateTime? dt) {
      if (dt == null) return '—';
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year}";
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Row(
            children: [
              Icon(Icons.home_work_outlined, color: brandOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isEmpty ? "Detalle de proyecto" : name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== TARJETA RESUMEN =====
                  Container(
                    decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF3D9C8)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Resumen de la obra",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Columna izquierda
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _projInfoRow(
                                    "Cliente",
                                    clientName.isEmpty ? "—" : clientName,
                                  ),
                                  const SizedBox(height: 4),
                                  _projInfoRow(
                                    "Ubicación",
                                    address.isEmpty ? "—" : address,
                                  ),
                                  const SizedBox(height: 4),
                                  _projInfoRow("Creado", _fmtDate(createdAt)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Columna derecha
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _projInfoRow("Inicio", _fmtDate(startDate)),
                                  const SizedBox(height: 4),
                                  _projInfoRow(
                                    "Fin estimado",
                                    _fmtDate(endDate),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _StatusPill(
                                        text: statusLabel,
                                        bg: bg,
                                        border: border,
                                        textColor: textColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Avance $progress%",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: LinearProgressIndicator(
                                                value: progress / 100.0,
                                                minHeight: 6,
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.5),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(brandOrange),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== TARJETA DE REGISTROS LIGADOS =====
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.link_outlined,
                              size: 18,
                              color: brandOrange,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Registros ligados a esta obra",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "En el siguiente paso vamos a mostrar aquí:",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProjBullet(
                                icon: Icons.build_outlined,
                                text: "Préstamos ligados a esta obra",
                              ),
                              _ProjBullet(
                                icon: Icons.assignment_turned_in_outlined,
                                text: "Solicitudes de herramientas / productos",
                              ),
                              _ProjBullet(
                                icon: Icons.report_problem_outlined,
                                text:
                                    "Reportes de daño filtrados por projectId",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "La idea es que desde aquí el admin vea todo el historial operacional asociado al proyecto.",
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Widget _projInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  /// Filita de info simple para el detalle de proyecto
  // =================== PROVEEDORES ===================

  Widget _buildSuppliersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Gestión de Proveedores", color: brandOrange),
        const SizedBox(height: 16),

        // ---- Formulario para registrar proveedor ----
        _PanelCard(
          bg: panelBg,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Input(_supEmpresaCtrl, hint: "Empresa", width: 200),
              _Input(
                _supNombreContactoCtrl,
                hint: "Nombre de contacto",
                width: 200,
              ),
              _Input(_supProductoCtrl, hint: "Producto principal", width: 200),
              _Input(_supTelefonoCtrl, hint: "Teléfono", width: 150),
              _Input(_supCorreoCtrl, hint: "Correo", width: 220),
              _Btn(
                label: "Agregar proveedor",
                color: brandOrange,
                onTap: _addSupplier,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ---- Tabla de proveedores ----
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Empresa",
            "Contacto",
            "Producto",
            "Teléfono",
            "Correo",
            "Acciones",
          ],
          flexes: const [3, 3, 3, 2, 3, 2],
        ),

        StreamBuilder<QuerySnapshot>(
          stream: _suppliersRef.orderBy('empresa').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar proveedores: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay proveedores registrados."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final empresa = (data['empresa'] ?? '') as String;
                final contacto = (data['nombreContacto'] ?? '') as String;
                final producto = (data['product'] ?? '') as String;
                final telefono = (data['telefono'] ?? '') as String;
                final correo = (data['correo'] ?? '') as String;

                return _Row(
                  flexes: const [3, 3, 3, 2, 3, 2],
                  cells: [
                    Text(empresa),
                    Text(contacto),
                    Text(producto),
                    Text(telefono),
                    Text(correo),
                    Row(
                      children: [
                        IconButton(
                          tooltip: "Editar proveedor",
                          onPressed: () => _editSupplier(doc),
                          icon: const Icon(Icons.edit_outlined),
                          color: brandOrange,
                        ),
                        IconButton(
                          tooltip: "Eliminar proveedor",
                          onPressed: () => doc.reference.delete(),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =================== PEDIDOS A PROVEEDORES (orders) ===================

  Widget _buildOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Pedidos a proveedores", color: brandOrange),
        const SizedBox(height: 16),

        // ----- FORMULARIO PARA CREAR PEDIDOS (incluye lote) -----
        _PanelCard(
          bg: panelBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nuevo pedido",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),

              // Dropdown de proveedores + producto
              StreamBuilder<QuerySnapshot>(
                stream: _suppliersRef.orderBy('empresa').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      "No hay proveedores registrados. Registra uno primero.",
                      style: TextStyle(color: Colors.black54),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSupplierForOrderId,
                              decoration: InputDecoration(
                                labelText: "Proveedor",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final empresa =
                                    (data['empresa'] ?? '') as String;
                                final contacto =
                                    (data['nombreContacto'] ?? '') as String;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    "$empresa (${contacto.isEmpty ? 'Sin contacto' : contacto})",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSupplierForOrderId = value;
                                  if (value != null) {
                                    final doc = docs.firstWhere(
                                      (d) => d.id == value,
                                    );
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    _orderProductCtrl.text =
                                        (data['product'] ?? '') as String;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _orderProductCtrl,
                              decoration: InputDecoration(
                                labelText: "Producto",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: _orderQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Cantidad",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              initialValue: _orderPriority,
                              decoration: InputDecoration(
                                labelText: "Prioridad",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Baja',
                                  child: Text('Baja'),
                                ),
                                DropdownMenuItem(
                                  value: 'Media',
                                  child: Text('Media'),
                                ),
                                DropdownMenuItem(
                                  value: 'Alta',
                                  child: Text('Alta'),
                                ),
                                DropdownMenuItem(
                                  value: 'Urgente',
                                  child: Text('Urgente'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _orderPriority = v);
                              },
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _Btn(
                            label: "Agregar a lista",
                            color: brandOrange,
                            onTap: () => _addOrderDraftLine(docs),
                          ),
                          const SizedBox(width: 12),
                          _Btn(
                            label: _orderDraftLines.isEmpty
                                ? "Crear pedido"
                                : "Crear ${_orderDraftLines.length} pedidos",
                            color: Colors.green,
                            onTap: () => _createOrdersFromDraft(),
                          ),
                        ],
                      ),

                      if (_orderDraftLines.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          "Pedidos en lote:",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children: _orderDraftLines.map((line) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFF3D9C8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${line.supplierName} - ${line.product}",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text("x${line.quantity}"),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      line.priority,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ----- LISTADO DE PEDIDOS -----
        Text(
          "Pedidos realizados",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: brandOrange,
          ),
        ),
        const SizedBox(height: 8),
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Proveedor",
            "Producto",
            "Cantidad",
            "Prioridad",
            "Estado",
            "Fecha",
            "Acciones",
          ],
          flexes: const [3, 3, 2, 2, 2, 3, 3],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _ordersRef.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar pedidos: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No se han registrado pedidos."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final proveedor = (data['supplierName'] ?? '') as String;
                final producto = (data['product'] ?? '') as String;
                final int cantidad = (data['quantity'] ?? 0) as int;
                final prioridad = (data['priority'] ?? '') as String;
                final status = (data['status'] ?? 'pendiente') as String;
                final createdAt = _formatTimestamp(
                  data['createdAt'] as Timestamp?,
                );

                Color chipColor;
                switch (prioridad) {
                  case 'Alta':
                    chipColor = Colors.orange.shade700;
                    break;
                  case 'Urgente':
                    chipColor = Colors.redAccent;
                    break;
                  case 'Media':
                    chipColor = Colors.blueGrey;
                    break;
                  default:
                    chipColor = Colors.green;
                }

                final canMarkDelivered = status != 'entregado';

                return _Row(
                  flexes: const [3, 3, 2, 2, 2, 3, 3],
                  cells: [
                    Text(proveedor),
                    Text(producto),
                    Text("$cantidad"),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        prioridad,
                        style: TextStyle(
                          color: chipColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(status),
                    Text(createdAt),
                    Row(
                      children: [
                        if (canMarkDelivered)
                          _SmallBtn(
                            label: "Entregado",
                            color: Colors.green,
                            onTap: () => _markOrderDelivered(doc),
                          )
                        else
                          const Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =================== ALMACÉN ===================

  Widget _buildWarehouseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Almacén", color: brandOrange),
        const SizedBox(height: 12),
        const Text(
          "Administra las herramientas y los productos almacenados para la obra.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 20),

        // ---------- BLOQUE: HERRAMIENTAS ----------
        Text(
          "Herramientas",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: brandOrange,
          ),
        ),
        const SizedBox(height: 10),

        // Formulario de herramientas
        _PanelCard(
          bg: panelBg,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Input(_herrCtrl, hint: "Nombre de la herramienta", width: 260),
              _Input(_stockCtrl, hint: "Stock inicial", width: 140),
              _Btn(
                label: "Agregar herramienta",
                color: brandOrange,
                onTap: _addHerramienta,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tabla de herramientas
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Herramienta",
            "Stock total",
            "Stock disp.",
            "Acciones",
          ],
          flexes: const [4, 2, 2, 3],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _toolsRef.orderBy('herr').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar herramientas: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Sin herramientas registradas."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final int stockTotal = (data['stockTotal'] ?? 0) as int;
                final int stockDisp =
                    (data['stockDisponible'] ?? stockTotal) as int;

                return _Row(
                  flexes: const [4, 2, 2, 3],
                  cells: [
                    Text(data["herr"] ?? ""),
                    Text("$stockTotal"),
                    Text("$stockDisp"),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Editar herramienta',
                          onPressed: () => _editHerr(doc),
                          icon: const Icon(Icons.edit_outlined),
                          color: brandOrange,
                        ),
                        IconButton(
                          tooltip: 'Eliminar herramienta',
                          onPressed: () => doc.reference.delete(),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 28),

        // ---------- BLOQUE: PRODUCTOS DE ALMACÉN ----------
        Text(
          "Productos de almacén",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: brandOrange,
          ),
        ),
        const SizedBox(height: 10),

        // Formulario de productos
        _PanelCard(
          bg: panelBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Registrar / actualizar producto de almacén",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Input(
                    _whProductCtrl,
                    hint: "Nombre del producto",
                    width: 220,
                  ),
                  _Input(_whQtyCtrl, hint: "Cantidad", width: 120),
                  _Input(
                    _whLocationCtrl,
                    hint: "Ubicación (ej: Bodega A, Estante 3)",
                    width: 260,
                  ),
                  _Btn(
                    label: "Guardar en almacén",
                    color: brandOrange,
                    onTap: _addWarehouseItem,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tabla de productos
        _TableHeader(
          color: brandOrange,
          titles: const ["Producto", "Cantidad", "Ubicación", "Acciones"],
          flexes: const [4, 2, 3, 3],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _warehouseRef.orderBy('product').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar almacén: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay productos registrados en almacén."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final product = (data['product'] ?? '') as String;
                final int qty = _toInt(data['quantity']); // por si viene String
                final location = (data['location'] ?? '') as String;

                return _Row(
                  flexes: const [4, 2, 3, 3],
                  cells: [
                    Text(product),
                    Text("$qty"),
                    Text(location.isEmpty ? "—" : location),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Editar producto',
                          onPressed: () => _editWarehouseItem(doc),
                          icon: const Icon(Icons.edit_outlined),
                          color: brandOrange,
                        ),
                        IconButton(
                          tooltip: 'Eliminar producto',
                          onPressed: () => doc.reference.delete(),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =================== HERRAMIENTAS ===================

  Widget _buildHerramientasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Gestión de Herramientas", color: brandOrange),
        const SizedBox(height: 16),
        _PanelCard(
          bg: panelBg,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Input(_herrCtrl, hint: "Nombre de la herramienta", width: 260),
              _Input(_stockCtrl, hint: "Stock inicial", width: 140),
              _Btn(
                label: "Agregar",
                color: brandOrange,
                onTap: _addHerramienta,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Herramienta",
            "Stock total",
            "Stock disp.",
            "Acciones",
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _toolsRef.orderBy('herr').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar herramientas: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Sin herramientas registradas."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final int stockTotal = (data['stockTotal'] ?? 0) as int;
                final int stockDisp =
                    (data['stockDisponible'] ?? stockTotal) as int;

                return _Row(
                  cells: [
                    Text(data["herr"] ?? ""),
                    Text("$stockTotal"),
                    Text("$stockDisp"),
                    Row(
                      children: [
                        _SmallBtn(
                          label: "Editar",
                          color: brandOrange,
                          onTap: () => _editHerr(doc),
                        ),
                        const SizedBox(width: 10),
                        _SmallBtn(
                          label: "Eliminar",
                          color: Colors.red,
                          onTap: () => doc.reference.delete(),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =================== REGISTROS + SOLICITUDES ===================

  Widget _buildRegistrosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Registro de préstamos", color: brandOrange),
        const SizedBox(height: 16),

        // ------- SOLICITUDES DE PRÉSTAMO (HERRAMIENTAS) -------
        Text(
          "Solicitudes de préstamo",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: brandOrange,
          ),
        ),
        const SizedBox(height: 8),
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Fecha",
            "Herramienta",
            "Empleado",
            "Cant.",
            "Estado",
            "Acciones",
          ],
          flexes: const [3, 3, 3, 1, 1, 2],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _requestsRef
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar solicitudes: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay solicitudes registradas."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final toolName =
                    (data['toolName'] ?? data['herr'] ?? '') as String;
                final empName =
                    (data['employeeName'] ?? data['empName'] ?? '') as String;

                final int qty = _toInt(
                  data['requestedQty'] ?? data['quantity'] ?? 1,
                );

                final status = (data['status'] ?? 'pendiente') as String;

                final createdAt = data['createdAt'] as Timestamp?;
                final approvedAt = data['approvedAt'] as Timestamp?;

                final fecha = _formatDateOnly(createdAt);
                final horaSolicitud = _formatHourFromTimestamp(createdAt);
                final horaAprobacion =
                    (status == 'aprobada' || status == 'entregada')
                    ? _formatHourFromTimestamp(approvedAt)
                    : '—';

                final isPendiente = status == 'pendiente';

                Color bg;
                Color border;
                Color text;
                switch (status) {
                  case 'aprobada':
                    bg = const Color(0xFFE9F7EF);
                    border = const Color(0xFF27AE60);
                    text = const Color(0xFF1E8449);
                    break;
                  case 'rechazada':
                    bg = const Color(0xFFFFEBEE);
                    border = const Color(0xFFC62828);
                    text = const Color(0xFFC62828);
                    break;
                  case 'entregada':
                    bg = const Color(0xFFE8F4FD);
                    border = const Color(0xFF1E88E5);
                    text = const Color(0xFF1565C0);
                    break;
                  default:
                    bg = const Color(0xFFFFF9E6);
                    border = const Color(0xFFF1C40F);
                    text = const Color(0xFF7D6608);
                }

                return _Row(
                  flexes: const [3, 3, 3, 1, 1, 2],
                  cells: [
                    // Fecha + horas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fecha),
                        const SizedBox(height: 2),
                        Text(
                          "Sol: $horaSolicitud   Apr: $horaAprobacion",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(toolName),
                    Text(empName),
                    Text("$qty", textAlign: TextAlign.center),
                    _StatusPill(
                      text: status,
                      bg: bg,
                      border: border,
                      textColor: text,
                    ),
                    Row(
                      children: [
                        if (isPendiente) ...[
                          IconButton(
                            tooltip: 'Aprobar',
                            onPressed: () => _aprobarSolicitud(doc),
                            icon: const Icon(Icons.check_circle_outline),
                            color: Colors.green,
                          ),
                          IconButton(
                            tooltip: 'Rechazar',
                            onPressed: () => _rechazarSolicitud(doc),
                            icon: const Icon(Icons.cancel_outlined),
                            color: Colors.red,
                          ),
                        ] else
                          const Text("—"),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 28),

        // ------- SOLICITUDES DE PRODUCTOS (ALMACÉN) -------
        Text(
          "Solicitudes de productos",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: brandOrange,
          ),
        ),
        const SizedBox(height: 8),

        // 🔹 Encabezado tipo Historial de préstamos
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Fecha",
            "Empleado",
            "Producto",
            "Cant.",
            "Estado",
            "Acciones",
          ],
          flexes: const [3, 3, 3, 1, 1, 2],
        ),

        StreamBuilder<QuerySnapshot>(
          stream: _warehouseRequestsRef
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar solicitudes: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay solicitudes de productos."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((requestDoc) {
                final data = requestDoc.data() as Map<String, dynamic>;

                final String empName =
                    (data['employeeName'] ?? data['empName'] ?? '') as String;
                final String productName =
                    (data['productName'] ?? data['product'] ?? '') as String;
                final int quantity = _toInt(data['quantity']);
                final String status = (data['status'] ?? 'pendiente') as String;

                // 🔹 Fechas/hora estilo Historial de préstamos
                final Timestamp? createdTs = data['createdAt'] as Timestamp?;
                final Timestamp? approvedTs = data['approvedAt'] as Timestamp?;

                String fecha = '—';
                String horaSol = '—';
                String horaApr = '—';

                if (createdTs != null) {
                  final dt = createdTs.toDate();
                  fecha =
                      '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year}';
                  horaSol = '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
                }

                if (approvedTs != null) {
                  final dt = approvedTs.toDate();
                  horaApr = '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
                }

                final bool isPending = status == 'pendiente';

                // 🔹 Colores del pill de estado
                Color bg;
                Color border;
                Color textColor;
                switch (status) {
                  case 'entregada':
                    bg = const Color(0xFFE8F4FD);
                    border = const Color(0xFF1E88E5);
                    textColor = const Color(0xFF1565C0);
                    break;
                  case 'rechazada':
                    bg = const Color(0xFFFFEBEE);
                    border = const Color(0xFFC62828);
                    textColor = const Color(0xFFC62828);
                    break;
                  default: // pendiente
                    bg = const Color(0xFFFFF9E6);
                    border = const Color(0xFFF1C40F);
                    textColor = const Color(0xFF7D6608);
                }

                return _Row(
                  flexes: const [3, 3, 3, 1, 1, 2],
                  cells: [
                    // 📅 Fecha + horas (doble renglón)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fecha),
                        Text(
                          'Sol: $horaSol   Apr: $horaApr',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    Text(empName),
                    Text(productName),
                    Text("$quantity"),

                    _StatusPill(
                      text: status,
                      bg: bg,
                      border: border,
                      textColor: textColor,
                    ),

                    // 🎛 Acciones con iconitos
                    Row(
                      children: [
                        if (isPending) ...[
                          IconButton(
                            tooltip: 'Marcar como entregada',
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () =>
                                _aprobarSolicitudAlmacen(requestDoc),
                          ),
                          IconButton(
                            tooltip: 'Rechazar solicitud',
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                _rechazarSolicitudAlmacen(requestDoc),
                          ),
                        ] else
                          const Text(
                            "—",
                            style: TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 28),

        // ------- HISTORIAL DE PRÉSTAMOS -------
        Text(
          "Historial de préstamos",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: brandOrange,
          ),
        ),
        const SizedBox(height: 8),
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Fecha",
            "Herramienta",
            "Empleado",
            "Estado",
            "Acciones",
          ],
          flexes: const [3, 2, 3, 1, 3],
        ),

        StreamBuilder<QuerySnapshot>(
          stream: _loansRef
              .orderBy('fechaCreacion', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar préstamos: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Sin registros de préstamos."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final estado = (data["estado"] ?? "No regresó") as String;

                final salidaRaw = (data["salida"] ?? "") as String;
                final regresoRaw = (data["regreso"] ?? "") as String;

                final fecha = _formatDateOnlyFromString(salidaRaw);
                final horaSalida = _formatHourFromString(salidaRaw);
                final horaRegreso = regresoRaw.isEmpty
                    ? "—"
                    : _formatHourFromString(regresoRaw);

                Color bg;
                Color border;
                Color textColor;
                if (estado == "Regresó") {
                  bg = const Color(0xFFE9F7EF);
                  border = const Color(0xFF27AE60);
                  textColor = const Color(0xFF1E8449);
                } else {
                  bg = const Color(0xFFFFEBEE);
                  border = const Color(0xFFC62828);
                  textColor = const Color(0xFFC62828);
                }

                return _Row(
                  flexes: const [3, 4, 4, 3, 3],
                  cells: [
                    // Fecha + horas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fecha),
                        const SizedBox(height: 2),
                        Text(
                          "Sal: $horaSalida   Reg: $horaRegreso",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(data["herr"] ?? ""),
                    Text(data["emp"] ?? ""),
                    _StatusPill(
                      text: estado,
                      bg: bg,
                      border: border,
                      textColor: textColor,
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: estado == "Regresó"
                              ? "Marcar NO regresó"
                              : "Marcar regresó",
                          onPressed: () => _marcarRegresoPrestamo(doc, estado),
                          icon: Icon(
                            estado == "Regresó"
                                ? Icons.undo
                                : Icons.check_circle_outline,
                          ),
                          color: estado == "Regresó"
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                        IconButton(
                          tooltip: "Reporte de daño",
                          onPressed: () => _openDamageReportDialog(doc),
                          icon: const Icon(Icons.build_outlined),
                          color: Colors.redAccent,
                        ),
                        IconButton(
                          tooltip: 'Eliminar registro',
                          onPressed: () => _confirmDeletePrestamo(doc),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _statusChipSolicitud(String status) {
    Color bg;
    Color border;
    Color textColor;

    switch (status) {
      case 'aprobada':
        bg = const Color(0xFFE9F7EF);
        border = const Color(0xFF27AE60);
        textColor = const Color(0xFF1E8449);
        break;
      case 'rechazada':
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFC62828);
        textColor = const Color(0xFFC62828);
        break;
      case 'entregada':
        bg = const Color(0xFFE8F4FD);
        border = const Color(0xFF1E88E5);
        textColor = const Color(0xFF1565C0);
        break;
      default: // pendiente u otro
        bg = const Color(0xFFFFF9E6);
        border = const Color(0xFFF1C40F);
        textColor = const Color(0xFF7D6608);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
  // =================== INCIDENTES ===================

  Widget _buildIncidentesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Incidentes de seguridad", color: brandOrange),
        const SizedBox(height: 12),
        const Text(
          "Incidentes detectados por la app móvil / cámara (casco, chaleco, riesgo, etc.).",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 16),

        _TableHeader(
          color: brandOrange,
          titles: const [
            "Fecha / hora",
            "Mensaje",
            "Riesgo",
            "Casco",
            "Chaleco",
            "Acciones",
          ],
          flexes: const [3, 4, 2, 2, 2, 3],
        ),

        StreamBuilder<QuerySnapshot>(
          stream: _incidentsRef
              .orderBy('fechaHora', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar incidentes: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay incidentes registrados."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // fechaHora puede venir como Timestamp o String
                final dynamic fechaRaw = data['fechaHora'];
                String fechaFmt;
                if (fechaRaw is Timestamp) {
                  fechaFmt = _formatTimestamp(fechaRaw);
                } else if (fechaRaw is String) {
                  fechaFmt = _formatDateString(fechaRaw);
                } else {
                  fechaFmt = '—';
                }

                final String mensaje = (data['mensaje'] ?? '').toString();
                final String riesgo = (data['riesgo'] ?? '')
                    .toString()
                    .toUpperCase();
                final bool casco = (data['casco'] ?? false) as bool;
                final bool chaleco = (data['chaleco'] ?? false) as bool;

                // colores para el riesgo
                Color rBg;
                Color rBorder;
                Color rText;
                switch (riesgo) {
                  case 'BAJO':
                    rBg = const Color(0xFFE9F7EF);
                    rBorder = const Color(0xFF27AE60);
                    rText = const Color.fromARGB(255, 3, 3, 3);
                    break;
                  case 'ALTO':
                    rBg = const Color(0xFFFFEBEE);
                    rBorder = const Color.fromRGBO(255, 83, 73, 1);
                    rText = const Color.fromARGB(255, 3, 3, 3);
                    break;
                  case 'MEDIO':
                    rBg = const Color(0xFFFFF9E6);
                    rBorder = const Color(0xFFF1C40F);
                    rText = const Color.fromARGB(255, 3, 3, 3);
                    break;
                  case 'MUY ALTO':
                    rBg = const Color(0xFFFFE6E6);
                    rBorder = const Color.fromRGBO(255, 0, 0, 1);
                    rText = const Color.fromARGB(255, 3, 3, 3);
                    break;
                  default:
                    rBg = const Color(0xFFE9F7EF);
                    rBorder = const Color.fromARGB(255, 67, 4, 255);
                    rText = const Color.fromARGB(255, 3, 3, 3);
                }

                return _Row(
                  flexes: const [3, 4, 2, 2, 2, 3],
                  cells: [
                    Text(fechaFmt),
                    Text(mensaje, overflow: TextOverflow.ellipsis),
                    _StatusPill(
                      text: riesgo.isEmpty ? 'N/A' : riesgo,
                      bg: rBg,
                      border: rBorder,
                      textColor: rText,
                    ),
                    Row(
                      children: [
                        _boolIcon(casco),
                        const SizedBox(width: 4),
                        Text(
                          casco ? "Sí" : "No",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _boolIcon(chaleco),
                        const SizedBox(width: 4),
                        Text(
                          chaleco ? "Sí" : "No",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blueGrey,
                          ),
                          tooltip: 'Editar incidente',
                          onPressed: () => _editIncident(doc),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Eliminar incidente',
                          onPressed: () => _confirmDeleteIncident(doc),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _editIncident(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final mensajeCtrl = TextEditingController(
      text: (data['mensaje'] ?? '').toString(),
    );
    String riesgo = (data['riesgo'] ?? 'MEDIO').toString().toUpperCase();
    bool casco = (data['casco'] ?? false) as bool;
    bool chaleco = (data['chaleco'] ?? false) as bool;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar incidente"),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: mensajeCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Mensaje",
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: riesgo,
                      decoration: const InputDecoration(labelText: "Riesgo"),
                      items: const [
                        DropdownMenuItem(value: 'ALTO', child: Text('Alto')),
                        DropdownMenuItem(value: 'MEDIO', child: Text('Medio')),
                        DropdownMenuItem(value: 'BAJO', child: Text('Bajo')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() => riesgo = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: casco,
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() => casco = v);
                      },
                      title: const Text("Casco"),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: chaleco,
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() => chaleco = v);
                      },
                      title: const Text("Chaleco"),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandOrange),
                  onPressed: () async {
                    await doc.reference.update({
                      'mensaje': mensajeCtrl.text.trim(),
                      'riesgo': riesgo,
                      'casco': casco,
                      'chaleco': chaleco,
                    });
                    if (mounted) Navigator.pop(ctx);
                    _showSnack("Incidente actualizado.");
                  },
                  child: const Text(
                    "Guardar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteIncident(DocumentSnapshot doc) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar incidente'),
        content: const Text('¿Seguro que quieres eliminar este incidente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await doc.reference.delete();
      _showSnack('Incidente eliminado.');
    }
  }

  // =================== REPORTES DE DAÑOS ===================

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Reportes de daños", color: brandOrange),
        const SizedBox(height: 12),
        const Text(
          "Reportes cuando una herramienta es regresada dañada o rota.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _TableHeader(
          color: brandOrange,
          titles: const [
            "Herramienta",
            "Empleado",
            "Tipo de daño",
            "Estado",
            "Fecha",
            "Acciones",
          ],
          flexes: const [3, 3, 3, 2, 3, 3],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _reportsRef
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar reportes: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay reportes registrados."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final toolName = (data['toolName'] ?? '') as String;
                final empName = (data['employeeName'] ?? '') as String;
                final damageType = (data['damageType'] ?? '') as String;
                final status = (data['status'] ?? 'pendiente') as String;
                final createdAt = _formatTimestamp(
                  data['createdAt'] as Timestamp?,
                );

                final canResolve = status != 'resuelto';

                return _Row(
                  flexes: const [3, 3, 3, 2, 3, 3],
                  cells: [
                    Text(toolName),
                    Text(empName),
                    Text(damageType),
                    Text(status),
                    Text(createdAt),
                    Row(
                      children: [
                        if (canResolve)
                          _SmallBtn(
                            label: "Marcar resuelto",
                            color: Colors.green,
                            onTap: () => _markReportResolved(doc),
                          )
                        else
                          const Text(
                            "Resuelto",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => doc.reference.delete(),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =================== CONSULTAS ===================

  Widget _buildConsultasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Consultas rápidas por ID", color: brandOrange),
        const SizedBox(height: 16),

        _PanelCard(
          bg: panelBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Elige el tipo de registro y escribe el ID de Firestore.",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _chipTipo("Cliente", 'cliente'),
                  _chipTipo("Empleado", 'empleado'),
                  _chipTipo("Herramienta", 'herramienta'),
                  _chipTipo("Préstamo", 'prestamo'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _consultaCtrl,
                      decoration: InputDecoration(
                        hintText: 'ID de documento (ej: abC123...)',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _consultarPorId(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _consultarPorId,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text(
                      "Buscar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        if (_consultaLoading)
          const Center(child: CircularProgressIndicator())
        else if (_consultaError != null)
          _PanelCard(
            bg: const Color(0xFFFFEBEE),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _consultaError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          )
        else if (_consultaData != null)
          _PanelCard(bg: Colors.white, child: _buildConsultaResultado())
        else
          const Text("Realiza una búsqueda para ver resultados."),
      ],
    );
  }

  Widget _chipTipo(String label, String value) {
    final bool selected = _consultaTipo == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _consultaTipo = value;
          _consultaData = null;
          _consultaError = null;
        });
      },
      selectedColor: brandOrange.withOpacity(0.9),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildConsultaResultado() {
    final data = _consultaData!;
    List<Widget> rows = [];

    if (_consultaTipo == 'cliente') {
      rows = [
        _kvRow("Nombre", data['nombre']),
        _kvRow("Correo", data['correo']),
        _kvRow("Teléfono", data['tel']),
        _kvRow(
          "Fecha registro",
          _formatTimestamp(data['fechaRegistro'] as Timestamp?),
        ),
      ];
    } else if (_consultaTipo == 'empleado') {
      final nombre = (data['nombre'] ?? '').toString();
      final apellidos = (data['apellidos'] ?? '').toString();
      rows = [
        _kvRow("Nombre completo", ('$nombre $apellidos').trim()),
        _kvRow("Correo", data['correo'] ?? data['email']),
        _kvRow("Rol", data['role']),
      ];
    } else if (_consultaTipo == 'herramienta') {
      rows = [
        _kvRow("Herramienta", data['herr']),
        _kvRow("Stock total", data['stockTotal']),
        _kvRow("Stock disponible", data['stockDisponible']),
      ];
    } else {
      rows = [
        _kvRow("Herramienta", data['herr']),
        _kvRow("Empleado", data['emp']),
        _kvRow("Salida", _formatDateString((data['salida'] ?? '').toString())),
        _kvRow(
          "Regreso",
          (data['regreso'] ?? '') == ''
              ? '—'
              : _formatDateString(data['regreso']),
        ),
        _kvRow("Estado", data['estado']),
      ];
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _kvRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? '—')),
        ],
      ),
    );
  }

  // =================== EMPLEADOS ===================

  Widget _buildEmpleadosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageTitle(text: "Gestión de Empleados", color: brandOrange),
        const SizedBox(height: 16),
        _TableHeader(
          color: brandOrange,
          titles: const ["Nombre", "Correo", "Puesto / Rol", "Acciones"],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _usersRef.orderBy('nombre', descending: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error al cargar empleados: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text("No hay empleados registrados."),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final String nombre = (data['nombre'] ?? '') as String;
                final String apellidos = (data['apellidos'] ?? '') as String;
                final String email =
                    (data['correo'] ?? data['email'] ?? '') as String;
                final String fullName = ('$nombre $apellidos').trim();
                String role = (data['role'] ?? '') as String;

                if (!kEmployeeRoles.contains(role)) {
                  role = '';
                }

                return _Row(
                  flexes: const [3, 3, 3, 2],
                  cells: [
                    Text(fullName.isEmpty ? 'Sin nombre' : fullName),
                    Text(email.isEmpty ? '—' : email),
                    SizedBox(
                      height: 40,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: role.isEmpty ? null : role,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text(
                          "Selecciona puesto",
                          overflow: TextOverflow.ellipsis,
                        ),
                        items: kEmployeeRoles.map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _updateUserRole(doc, value);
                        },
                      ),
                    ),
                    Row(
                      children: [
                        if (role == 'Admin')
                          const Text(
                            "Administrador",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          )
                        else
                          const Text(
                            "Empleado",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =================== LÓGICA FIRESTORE / ACCIONES ===================

  Future<void> _addCliente() async {
    if (_nombreCtrl.text.isEmpty ||
        _correoCtrl.text.isEmpty ||
        _telCtrl.text.isEmpty) {
      return;
    }

    await _clientsRef.add({
      "nombre": _nombreCtrl.text.trim(),
      "correo": _correoCtrl.text.trim(),
      "tel": _telCtrl.text.trim(),
      "fechaRegistro": FieldValue.serverTimestamp(),
    });

    _nombreCtrl.clear();
    _correoCtrl.clear();
    _telCtrl.clear();
  }

  void _editCliente(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final n = TextEditingController(text: data["nombre"] ?? "");
    final co = TextEditingController(text: data["correo"] ?? "");
    final t = TextEditingController(text: data["tel"] ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return _EditDialog(
          title: "Editar Cliente",
          children: [
            _Input(n, hint: "Nombre"),
            const SizedBox(height: 10),
            _Input(co, hint: "Correo"),
            const SizedBox(height: 10),
            _Input(t, hint: "Teléfono"),
          ],
          onSave: () async {
            await doc.reference.update({
              "nombre": n.text.trim(),
              "correo": co.text.trim(),
              "tel": t.text.trim(),
            });
            if (mounted) Navigator.pop(context);
          },
        );
      },
    );
  }

  void _openClientActivitiesDialog(DocumentSnapshot clientDoc) {
    final clientData = clientDoc.data() as Map<String, dynamic>;
    final String clientName = (clientData['nombre'] ?? '') as String;
    final String clientEmail = (clientData['correo'] ?? '') as String;

    String selectedType = 'llamada';
    String selectedStatus = 'pendiente';
    String? selectedUserId;
    String selectedUserName = '';

    final TextEditingController notesCtrl = TextEditingController();
    final TextEditingController dateCtrl = TextEditingController(
      text: DateTime.now().toString().substring(0, 16), // yyyy-MM-dd HH:mm
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              title: Row(
                children: [
                  Icon(Icons.event_note_outlined, color: brandOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Actividades - $clientName",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (clientEmail.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            clientEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                      // ===== TARJETA: NUEVA ACTIVIDAD =====
                      Container(
                        decoration: BoxDecoration(
                          color: panelBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE4D7FF)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Nueva actividad",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Responsable
                            StreamBuilder<QuerySnapshot>(
                              stream: _usersRef.orderBy('nombre').snapshots(),
                              builder: (context, snapshotUsers) {
                                if (!snapshotUsers.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: LinearProgressIndicator(),
                                  );
                                }

                                final docs = snapshotUsers.data!.docs;
                                if (docs.isEmpty) {
                                  return const Text(
                                    "No hay empleados registrados para asignar.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  );
                                }

                                return DropdownButtonFormField<String>(
                                  value: selectedUserId,
                                  decoration: InputDecoration(
                                    labelText: "Responsable",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: docs.map((uDoc) {
                                    final uData =
                                        uDoc.data() as Map<String, dynamic>;
                                    final nombre =
                                        (uData['nombre'] ?? '') as String;
                                    final apellidos =
                                        (uData['apellidos'] ?? '') as String;
                                    final fullName = ('$nombre $apellidos')
                                        .trim();
                                    return DropdownMenuItem<String>(
                                      value: uDoc.id,
                                      child: Text(
                                        fullName.isEmpty
                                            ? 'Sin nombre'
                                            : fullName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final match = docs.firstWhere(
                                      (d) => d.id == value,
                                    );
                                    final uData =
                                        match.data() as Map<String, dynamic>;
                                    final nombre =
                                        (uData['nombre'] ?? '') as String;
                                    final apellidos =
                                        (uData['apellidos'] ?? '') as String;
                                    final fullName = ('$nombre $apellidos')
                                        .trim();

                                    setStateDialog(() {
                                      selectedUserId = value;
                                      selectedUserName = fullName;
                                    });
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            // Tipo y Estado
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedType,
                                    decoration: InputDecoration(
                                      labelText: "Tipo",
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'llamada',
                                        child: Text('Llamada'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'visita',
                                        child: Text('Visita'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'reunion',
                                        child: Text('Reunión'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cotizacion',
                                        child: Text('Cotización enviada'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cobro',
                                        child: Text('Recordatorio de cobro'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'nota',
                                        child: Text('Nota'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setStateDialog(() => selectedType = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: "Estado",
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'pendiente',
                                        child: Text('Pendiente'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'hecho',
                                        child: Text('Hecho'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cancelado',
                                        child: Text('Cancelado'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setStateDialog(() => selectedStatus = v);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Fecha y hora
                            TextField(
                              controller: dateCtrl,
                              decoration: InputDecoration(
                                labelText: "Fecha y hora (yyyy-MM-dd HH:mm)",
                                helperText:
                                    "Ejemplo: 2025-11-30 10:30. Si se deja mal, se usa la fecha actual.",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Notas
                            TextField(
                              controller: notesCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: "Notas / comentarios",
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Parse fecha
                                  DateTime due;
                                  try {
                                    due = DateTime.parse(
                                      dateCtrl.text.trim().replaceFirst(
                                        ' ',
                                        'T',
                                      ),
                                    );
                                  } catch (_) {
                                    due = DateTime.now();
                                  }

                                  await _activitiesRef.add({
                                    'clientId': clientDoc.id,
                                    'clientName': clientName,
                                    'projectId': '',
                                    'projectName': '',
                                    'userId': selectedUserId ?? '',
                                    'userName': selectedUserName,
                                    'type': selectedType,
                                    'status': selectedStatus,
                                    'dueAt': Timestamp.fromDate(due),
                                    'notes': notesCtrl.text.trim(),
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  if (mounted) {
                                    _showSnack("Actividad registrada.");
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_task,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  "Guardar actividad",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===== TARJETA: HISTORIAL =====
                      Row(
                        children: const [
                          Icon(Icons.timeline, size: 18, color: Colors.black54),
                          SizedBox(width: 6),
                          Text(
                            "Historial de actividades",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: SizedBox(
                          height: 260,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _activitiesRef
                                .where('clientId', isEqualTo: clientDoc.id)
                                .orderBy('dueAt', descending: true)
                                .snapshots(),
                            builder: (context, snapActs) {
                              if (snapActs.hasError) {
                                return Text(
                                  "Error al cargar actividades: ${snapActs.error}",
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              if (snapActs.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapActs.hasData ||
                                  snapActs.data!.docs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "Aún no hay actividades para este cliente.",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                );
                              }

                              return ListView(
                                children: snapActs.data!.docs.map((aDoc) {
                                  final aData =
                                      aDoc.data() as Map<String, dynamic>;
                                  final String type =
                                      (aData['type'] ?? '') as String;
                                  final String status =
                                      (aData['status'] ?? '') as String;
                                  final String userName =
                                      (aData['userName'] ?? '') as String;
                                  final String notes =
                                      (aData['notes'] ?? '') as String;
                                  final String projectName =
                                      (aData['projectName'] ?? '') as String;
                                  final Timestamp? dueTs =
                                      aData['dueAt'] as Timestamp?;
                                  final String fecha = _formatTimestamp(dueTs);

                                  // Colores del status
                                  Color bg;
                                  Color border;
                                  Color textColor;
                                  switch (status) {
                                    case 'hecho':
                                      bg = const Color(0xFFE9F7EF);
                                      border = const Color(0xFF27AE60);
                                      textColor = const Color(0xFF1E8449);
                                      break;
                                    case 'cancelado':
                                      bg = const Color(0xFFFFEBEE);
                                      border = const Color(0xFFC62828);
                                      textColor = const Color(0xFFC62828);
                                      break;
                                    default: // pendiente
                                      bg = const Color(0xFFFFF9E6);
                                      border = const Color(0xFFF1C40F);
                                      textColor = const Color(0xFF7D6608);
                                  }

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFEFEFEF),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 130,
                                          child: Text(
                                            fecha,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      type.toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  _StatusPill(
                                                    text: status,
                                                    bg: bg,
                                                    border: border,
                                                    textColor: textColor,
                                                  ),
                                                ],
                                              ),
                                              if (userName.isNotEmpty)
                                                Text(
                                                  "Responsable: $userName",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              if (projectName.isNotEmpty)
                                                Text(
                                                  "Proyecto: $projectName",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              if (notes.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Text(
                                                    notes,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cerrar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addSupplier() async {
    if (_supEmpresaCtrl.text.isEmpty ||
        _supNombreContactoCtrl.text.isEmpty ||
        _supProductoCtrl.text.isEmpty) {
      _showSnack("Empresa, contacto y producto son obligatorios.");
      return;
    }

    await _suppliersRef.add({
      "empresa": _supEmpresaCtrl.text.trim(),
      "nombreContacto": _supNombreContactoCtrl.text.trim(),
      "product": _supProductoCtrl.text.trim(),
      "telefono": _supTelefonoCtrl.text.trim(),
      "correo": _supCorreoCtrl.text.trim(),
      "fechaRegistro": FieldValue.serverTimestamp(),
    });

    _supEmpresaCtrl.clear();
    _supNombreContactoCtrl.clear();
    _supProductoCtrl.clear();
    _supTelefonoCtrl.clear();
    _supCorreoCtrl.clear();
  }

  void _editSupplier(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final empresa = TextEditingController(text: data["empresa"] ?? "");
    final contacto = TextEditingController(text: data["nombreContacto"] ?? "");
    final producto = TextEditingController(text: data["product"] ?? "");
    final tel = TextEditingController(text: data["telefono"] ?? "");
    final correo = TextEditingController(text: data["correo"] ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return _EditDialog(
          title: "Editar Proveedor",
          children: [
            _Input(empresa, hint: "Empresa"),
            const SizedBox(height: 10),
            _Input(contacto, hint: "Nombre de contacto"),
            const SizedBox(height: 10),
            _Input(producto, hint: "Producto"),
            const SizedBox(height: 10),
            _Input(tel, hint: "Teléfono"),
            const SizedBox(height: 10),
            _Input(correo, hint: "Correo"),
          ],
          onSave: () async {
            await doc.reference.update({
              "empresa": empresa.text.trim(),
              "nombreContacto": contacto.text.trim(),
              "product": producto.text.trim(),
              "telefono": tel.text.trim(),
              "correo": correo.text.trim(),
            });
            if (mounted) Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _addHerramienta() async {
    if (_herrCtrl.text.isEmpty || _stockCtrl.text.isEmpty) return;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    await _toolsRef.add({
      "herr": _herrCtrl.text.trim(),
      "stockTotal": stock,
      "stockDisponible": stock,
    });
    _herrCtrl.clear();
    _stockCtrl.clear();
  }

  void _editHerr(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final he = TextEditingController(text: data["herr"] ?? "");
    final st = TextEditingController(text: "${data["stockTotal"] ?? 0}");
    final sd = TextEditingController(
      text: "${data["stockDisponible"] ?? data["stockTotal"] ?? 0}",
    );

    showDialog(
      context: context,
      builder: (_) {
        return _EditDialog(
          title: "Editar Herramienta",
          children: [
            _Input(he, hint: "Herramienta"),
            const SizedBox(height: 10),
            _Input(st, hint: "Stock total"),
            const SizedBox(height: 10),
            _Input(sd, hint: "Stock disponible"),
          ],
          onSave: () async {
            final stockTotal = int.tryParse(st.text.trim()) ?? 0;
            final stockDisp = int.tryParse(sd.text.trim()) ?? 0;
            await doc.reference.update({
              "herr": he.text.trim(),
              "stockTotal": stockTotal,
              "stockDisponible": stockDisp,
            });
            if (mounted) Navigator.pop(context);
          },
        );
      },
    );
  }

  // ----- Aprobación / rechazo de solicitudes -----

  Future<void> _aprobarSolicitud(DocumentSnapshot reqDoc) async {
    final data = reqDoc.data() as Map<String, dynamic>;
    final toolId = data['toolId'] as String?;
    final int qty = (data['requestedQty'] ?? 1) as int;
    final String toolName = (data['toolName'] ?? '') as String;
    final String empName = (data['employeeName'] ?? '') as String;

    // 👉 NUEVO: tomamos también el ID y correo del empleado desde la solicitud
    final String empId = (data['employeeId'] ?? '') as String;
    final String empEmail = (data['employeeEmail'] ?? '') as String;

    if (toolId == null || toolId.isEmpty) {
      _showSnack("La solicitud no tiene toolId.");
      return;
    }

    final toolRef = _toolsRef.doc(toolId);

    try {
      await _db.runTransaction((tx) async {
        final toolSnap = await tx.get(toolRef);
        if (!toolSnap.exists) {
          throw Exception('HERR_NO_EXISTE');
        }

        final toolData = toolSnap.data() as Map<String, dynamic>;
        final int disponible = (toolData['stockDisponible'] ?? 0) as int;

        if (disponible < qty) {
          throw Exception('STOCK_INSUFICIENTE');
        }

        // Actualizamos stock
        tx.update(toolRef, {'stockDisponible': disponible - qty});

        // Creamos préstamo y AHORA guarda también employeeId / employeeEmail
        final loanRef = _loansRef.doc();
        tx.set(loanRef, {
          "herr": toolName,
          "emp": empName,
          "employeeId": empId,
          "employeeEmail": empEmail,
          "salida": DateTime.now().toIso8601String(),
          "regreso": "",
          "estado": "No regresó",
          "requestId": reqDoc.id,
          "cantidad": qty,
          "fechaCreacion": FieldValue.serverTimestamp(),
        });

        // Marcamos la solicitud como aprobada
        tx.update(reqDoc.reference, {
          "status": "aprobada",
          "approvedAt": FieldValue.serverTimestamp(),
        });
      });

      _showSnack("Solicitud aprobada correctamente.");
    } catch (e) {
      if (e.toString().contains('STOCK_INSUFICIENTE')) {
        _showSnack("No hay stock suficiente para aprobar.");
      } else {
        _showSnack("Error al aprobar: $e");
      }
    }
  }

  Future<void> _rechazarSolicitud(DocumentSnapshot reqDoc) async {
    await reqDoc.reference.update({
      "status": "rechazada",
      "rejectedAt": FieldValue.serverTimestamp(),
    });
    _showSnack("Solicitud rechazada.");
  }

  Future<void> _marcarRegresoPrestamo(
    DocumentSnapshot loanDoc,
    String estadoActual,
  ) async {
    final data = loanDoc.data() as Map<String, dynamic>;
    final String? toolName = data['herr'] as String?;
    final String? requestId = data['requestId'] as String?;
    final int qty = data['cantidad'] is int ? data['cantidad'] as int : 1;

    final toolQuery = await _toolsRef
        .where('herr', isEqualTo: toolName)
        .limit(1)
        .get();
    if (toolQuery.docs.isEmpty) {
      _showSnack("No se encontró la herramienta para actualizar stock.");
      return;
    }
    final toolRef = toolQuery.docs.first.reference;

    try {
      await _db.runTransaction((tx) async {
        final toolSnap = await tx.get(toolRef);
        if (!toolSnap.exists) return;

        final toolData = toolSnap.data() as Map<String, dynamic>;
        final int disponible = (toolData['stockDisponible'] ?? 0) as int;

        final int nuevoDisponible = estadoActual == "Regresó"
            ? (disponible - qty)
            : (disponible + qty);

        tx.update(toolRef, {'stockDisponible': nuevoDisponible});

        if (estadoActual == "Regresó") {
          tx.update(loanDoc.reference, {"estado": "No regresó", "regreso": ""});
        } else {
          tx.update(loanDoc.reference, {
            "estado": "Regresó",
            "regreso": DateTime.now().toIso8601String(),
          });
        }

        if (requestId != null && requestId.isNotEmpty) {
          final reqRef = _requestsRef.doc(requestId);
          if (estadoActual == "Regresó") {
            tx.update(reqRef, {
              "status": "aprobada",
              "deliveredAt": FieldValue.delete(),
            });
          } else {
            tx.update(reqRef, {
              "status": "entregada",
              "deliveredAt": FieldValue.serverTimestamp(),
            });
          }
        }
      });

      _showSnack("Préstamo actualizado y stock ajustado.");
    } catch (e) {
      _showSnack("Error al actualizar préstamo: $e");
    }
  }

  Future<void> _aprobarSolicitudAlmacen(DocumentSnapshot reqDoc) async {
    final data = reqDoc.data() as Map<String, dynamic>;

    final String productId = (data['productId'] ?? '') as String;
    final int qty = _toInt(data['quantity']);

    if (productId.isEmpty) {
      _showSnack("La solicitud no tiene productId.");
      return;
    }

    final prodRef = _warehouseRef.doc(productId);

    try {
      await _db.runTransaction((tx) async {
        final prodSnap = await tx.get(prodRef);
        if (!prodSnap.exists) {
          throw Exception('PROD_NO_EXISTE');
        }

        final prodData = prodSnap.data() as Map<String, dynamic>;
        final int disponible = (prodData['quantity'] ?? 0) as int;

        if (disponible < qty) {
          throw Exception('STOCK_INSUFICIENTE');
        }

        // Descontar stock del almacén
        tx.update(prodRef, {'quantity': disponible - qty});

        // Marcar solicitud como entregada
        tx.update(reqDoc.reference, {
          'status': 'entregada',
          'approvedAt': FieldValue.serverTimestamp(),
          'deliveredAt': FieldValue.serverTimestamp(),
        });
      });

      _showSnack("Solicitud de almacén aprobada y entregada.");
    } catch (e) {
      if (e.toString().contains('STOCK_INSUFICIENTE')) {
        _showSnack("No hay stock suficiente en almacén.");
      } else {
        _showSnack("Error al aprobar solicitud de almacén: $e");
      }
    }
  }

  Future<void> _rechazarSolicitudAlmacen(DocumentSnapshot reqDoc) async {
    try {
      await reqDoc.reference.update({
        'status': 'rechazada',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      _showSnack("Solicitud de almacén rechazada.");
    } catch (e) {
      _showSnack("Error al rechazar solicitud de almacén: $e");
    }
  }

  Future<void> _confirmDeletePrestamo(DocumentSnapshot doc) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text(
          '¿Seguro que quieres eliminar este registro de préstamo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await doc.reference.delete();
      _showSnack('Registro eliminado.');
    }
  }

  Future<void> _updateUserRole(DocumentSnapshot userDoc, String newRole) async {
    try {
      await userDoc.reference.update({'role': newRole});
      _showSnack("Puesto actualizado a $newRole");
    } catch (e) {
      _showSnack("Error al actualizar puesto: $e");
    }
  }

  // ----- ALMACÉN -----

  Future<void> _addWarehouseItem() async {
    final name = _whProductCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack("Ingresa el nombre del producto.");
      return;
    }

    final qty = int.tryParse(_whQtyCtrl.text.trim());
    if (qty == null || qty < 0) {
      _showSnack("La cantidad debe ser un número válido.");
      return;
    }

    await _warehouseRef.add({
      'product': name,
      'quantity': qty,
      'location': _whLocationCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _whProductCtrl.clear();
    _whQtyCtrl.clear();
    _whLocationCtrl.clear();
    _showSnack("Producto guardado en almacén.");
  }

  void _editWarehouseItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final p = TextEditingController(text: data['product']?.toString() ?? '');
    final q = TextEditingController(text: (data['quantity'] ?? 0).toString());
    final l = TextEditingController(text: data['location']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return _EditDialog(
          title: "Editar producto de almacén",
          children: [
            _Input(p, hint: "Producto"),
            const SizedBox(height: 10),
            _Input(q, hint: "Cantidad"),
            const SizedBox(height: 10),
            _Input(l, hint: "Ubicación"),
          ],
          onSave: () async {
            final qty = int.tryParse(q.text.trim()) ?? 0;
            await doc.reference.update({
              'product': p.text.trim(),
              'quantity': qty,
              'location': l.text.trim(),
            });
            if (mounted) Navigator.pop(context);
          },
        );
      },
    );
  }

  // ----- PEDIDOS: lote, creación y marcado entregado -----

  bool _addOrderDraftLine(
    List<QueryDocumentSnapshot> supplierDocs, {
    bool silent = false,
  }) {
    if (_selectedSupplierForOrderId == null) {
      if (!silent) _showSnack("Selecciona un proveedor.");
      return false;
    }
    final product = _orderProductCtrl.text.trim();
    if (product.isEmpty) {
      if (!silent) _showSnack("Ingresa el producto.");
      return false;
    }
    final qty = int.tryParse(_orderQtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      if (!silent) _showSnack("La cantidad debe ser un número mayor a 0.");
      return false;
    }

    final matching = supplierDocs
        .where((d) => d.id == _selectedSupplierForOrderId)
        .toList();
    if (matching.isEmpty) {
      if (!silent) _showSnack("Proveedor no encontrado.");
      return false;
    }
    final supDoc = matching.first;
    final data = supDoc.data() as Map<String, dynamic>;
    final supplierName = (data['empresa'] ?? '') as String;
    final supplierEmail = (data['correo'] ?? '') as String;

    setState(() {
      _orderDraftLines.add(
        _OrderDraftLine(
          supplierId: supDoc.id,
          supplierName: supplierName,
          supplierEmail: supplierEmail,
          product: product,
          quantity: qty,
          priority: _orderPriority,
        ),
      );
    });

    _orderProductCtrl.clear();
    _orderQtyCtrl.clear();

    if (!silent) {
      _showSnack("Pedido agregado a la lista.");
    }

    return true;
  }

  Future<void> _createOrdersFromDraft() async {
    // Si no hay lote, tomamos la línea actual como un solo pedido
    if (_orderDraftLines.isEmpty) {
      final suppliersSnap = await _suppliersRef.orderBy('empresa').get();
      final docs = suppliersSnap.docs;
      if (!_addOrderDraftLine(docs, silent: true)) return;
    }

    final linesToSave = List<_OrderDraftLine>.from(_orderDraftLines);
    setState(() {
      _orderDraftLines.clear();
    });

    try {
      for (final line in linesToSave) {
        await _createOrderDocument(line);
      }

      _orderPriority = 'Media';
      _orderProductCtrl.clear();
      _orderQtyCtrl.clear();

      _showSnack(
        linesToSave.length == 1
            ? "Pedido creado y enviado al proveedor."
            : "${linesToSave.length} pedidos creados y enviados.",
      );
    } catch (e) {
      _showSnack("Error al crear pedidos: $e");
    }
  }

  Future<void> _createOrderDocument(_OrderDraftLine line) async {
    await _ordersRef.add({
      'supplierId': line.supplierId,
      'supplierName': line.supplierName,
      'supplierEmail': line.supplierEmail,
      'product': line.product,
      'quantity': line.quantity,
      'priority': line.priority,
      'status': 'pendiente',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (line.supplierEmail.isNotEmpty) {
      await _sendOrderEmail(
        toEmail: line.supplierEmail,
        empresa: line.supplierName,
        product: line.product,
        cantidad: line.quantity,
        prioridad: line.priority,
      );
    }
  }

  Future<void> _markOrderDelivered(DocumentSnapshot orderDoc) async {
    try {
      await orderDoc.reference.update({
        'status': 'entregado',
        'deliveredAt': FieldValue.serverTimestamp(),
      });
      _showSnack("Pedido marcado como entregado.");
    } catch (e) {
      _showSnack("Error al actualizar pedido: $e");
    }
  }

  Future<void> _sendOrderEmail({
    required String toEmail,
    required String empresa,
    required String product,
    required int cantidad,
    required String prioridad,
  }) async {
    final subject = Uri.encodeComponent("Pedido de $product - GeoToolTrack");
    final body = Uri.encodeComponent(
      "Hola $empresa,\n\n"
      "Te solicito el siguiente pedido:\n\n"
      "- Producto: $product\n"
      "- Cantidad: $cantidad\n"
      "- Prioridad: $prioridad\n\n"
      "Enviado desde GeoToolTrack.\n",
    );

    final uri = Uri.parse("mailto:$toEmail?subject=$subject&body=$body");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Si falla, no truena la app, solo no abre el correo
    }
  }

  // ----- REPORTES DE DAÑOS -----

  void _openDamageReportDialog(DocumentSnapshot loanDoc) {
    final data = loanDoc.data() as Map<String, dynamic>;
    final toolName = (data['herr'] ?? '') as String;
    final empName = (data['emp'] ?? '') as String;

    String damageType = 'Daño leve';
    final TextEditingController notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text("Reporte de daño"),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Herramienta: $toolName\nEmpleado: $empName",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: damageType,
                      decoration: const InputDecoration(
                        labelText: "Tipo de daño",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Daño leve',
                          child: Text('Daño leve'),
                        ),
                        DropdownMenuItem(
                          value: 'Daño moderado',
                          child: Text('Daño moderado'),
                        ),
                        DropdownMenuItem(
                          value: 'Daño grave / rota',
                          child: Text('Daño grave / rota'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() => damageType = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Descripción / notas",
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveDamageReport(
                      loanDoc: loanDoc,
                      damageType: damageType,
                      notes: notesCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: brandOrange),
                  child: const Text(
                    "Guardar reporte",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveDamageReport({
    required DocumentSnapshot loanDoc,
    required String damageType,
    required String notes,
  }) async {
    final data = loanDoc.data() as Map<String, dynamic>;
    final toolName = (data['herr'] ?? '') as String;
    final empName = (data['emp'] ?? '') as String;

    // 👉 NUEVO: leemos también el employeeId y employeeEmail del préstamo
    final String empId = (data['employeeId'] ?? '') as String;
    final String empEmail = (data['employeeEmail'] ?? '') as String;

    await _reportsRef.add({
      'loanId': loanDoc.id,
      'toolName': toolName,
      'employeeName': empName,
      'employeeId': empId, // 👈 clave para el empleado
      'employeeEmail': empEmail, // opcional pero útil
      'damageType': damageType,
      'notes': notes,
      'status': 'pendiente',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await loanDoc.reference.update({'hasDamageReport': true});

    _showSnack("Reporte de daño creado.");
  }

  Future<void> _markReportResolved(DocumentSnapshot reportDoc) async {
    try {
      await reportDoc.reference.update({
        'status': 'resuelto',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      _showSnack("Reporte marcado como resuelto.");
    } catch (e) {
      _showSnack("Error al actualizar reporte: $e");
    }
  }

  // ----- SNACKBAR -----

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// =============== WIDGETS AUXILIARES ===============

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color = Colors.black;
  final bool compact;
  final int? badge;

  const _SideItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
    this.compact = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? (selected ? Colors.black : Colors.black87);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: selected
            ? BoxDecoration(
                color: Colors.black12.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Row(
          mainAxisAlignment: compact
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, color: color ?? Colors.black87),
            if (!compact) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: baseColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badge != null && badge! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : badge!.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProjBullet({Key? key, required this.icon, required this.text})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _PageTitle({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;
  final Color bg;
  const _PanelCard({required this.child, required this.bg});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3D9C8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double? width;
  const _Input(this.controller, {required this.hint, this.width});
  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
    return width != null ? SizedBox(width: width, child: field) : field;
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> titles;
  final Color color;
  final List<int>? flexes;

  const _TableHeader({required this.titles, required this.color, this.flexes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: List.generate(titles.length, (index) {
          final title = titles[index];

          final flex = (flexes != null && index < flexes!.length)
              ? flexes![index]
              : (title == "Acciones"
                    ? 2
                    : title == "Estado"
                    ? 1 // 👈 Estado más angosto en todas las tablas
                    : 3);

          return Expanded(
            flex: flex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 3,
                      width: 10.0 + title.length * 6.0,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<Widget> cells;
  final List<int>? flexes;
  const _Row({required this.cells, this.flexes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6, // antes 14 → filas más bajitas
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(cells.length, (i) {
          final flex = (flexes != null && i < flexes!.length)
              ? flexes![i]
              : (i == cells.length - 1 ? 2 : 3);

          return Expanded(
            flex: flex,
            child: Align(alignment: Alignment.centerLeft, child: cells[i]),
          );
        }),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EditDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  const _EditDialog({
    required this.title,
    required this.children,
    required this.onSave,
  });
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD76728),
          ),
          child: const Text("Guardar", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
