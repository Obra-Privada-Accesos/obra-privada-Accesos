// lib/screens/employee_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:obraprivada/widgets/chatbot_fab.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===== Estados de la vista de Clima =====
enum ViewState { idle, loading, success, error }

/// Helper para capitalizar
String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});
  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final Color brandOrange = const Color(0xFFD76728);

  // 🔥 Firestore
  final _db = FirebaseFirestore.instance;
  late final CollectionReference _toolsRef;
  late final CollectionReference _loansRef;
  late final CollectionReference _requestsRef;
  late final CollectionReference _reportsRef;
  late final CollectionReference _activitiesRef;
  late final CollectionReference _warehouseRef; // productos de almacén
  late final CollectionReference _warehouseRequestsRef; // solicitudes almacén

  // Datos del empleado
  final _nameCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();

  // ID y correo del empleado (para ligar con reportes / actividades)
  String? _currentUserId;
  String? _currentUserEmail;

  // Solicitud de herramienta
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  String? _selectedToolId;
  String? _selectedToolName;
  int _selectedToolDisponible = 0;

  // Solicitud productos de almacén
  final TextEditingController _whQtyCtrl = TextEditingController(text: '1');
  String? _selectedWhProductId;
  String? _selectedWhProductName;
  int _selectedWhDisponible = 0;

  @override
  void initState() {
    super.initState();
    _toolsRef = _db.collection('tools');
    _loansRef = _db.collection('loans');
    _requestsRef = _db.collection('requests');
    _reportsRef = _db.collection('reports');
    _activitiesRef = _db.collection('activities');
    _warehouseRef = _db.collection('warehouse');
    _warehouseRequestsRef = _db.collection('warehouseRequests');
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    final nombre =
        prefs.getString('current_nombre') ??
        prefs.getString('user_first_name') ??
        'Empleado';
    final apellidos =
        prefs.getString('current_apellidos') ??
        prefs.getString('user_last_name') ??
        '';
    final role =
        prefs.getString('current_role') ??
        prefs.getString('user_role') ??
        'Empleado';

    // UID y correo del empleado
    final uid = prefs.getString('current_uid') ?? prefs.getString('user_uid');
    final email =
        prefs.getString('current_email') ?? prefs.getString('user_email');

    setState(() {
      _nameCtrl.text = ('$nombre $apellidos').trim();
      _positionCtrl.text = role;
      _currentUserId = uid;
      _currentUserEmail = email;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    _qtyCtrl.dispose();
    _whQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatbotFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            // ================== TOP BAR ==================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Izquierda: GeoToolTrack
                  Text(
                    "GeoToolTrack",
                    style: TextStyle(
                      color: brandOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),

                  // Centro: Panel de Empleado
                  Expanded(
                    child: Center(
                      child: Text(
                        "Panel de Empleado",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ),

                  // Botón CLIMA
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmployeeWeatherScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.cloud_outlined,
                      color: brandOrange,
                      size: 18,
                    ),
                    label: Text(
                      "Clima",
                      style: TextStyle(
                        color: brandOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Cerrar sesión
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                    label: const Text(
                      "Cerrar sesión",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================== CONTENIDO ==================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _inicioView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatActivityDate(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  // 👉 FECHA CORTA SOLO PARA ALMACÉN
  String _formatWhDate(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  // =================== INICIO ===================
  Widget _inicioView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Info empleado
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3D9C8)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _InfoRow(title: "Empleado", value: _nameCtrl.text),
                ),
                Expanded(
                  child: _InfoRow(title: "Puesto", value: _positionCtrl.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const SizedBox(height: 28),

          // ===== MIS SOLICITUDES =====
          Text(
            "Mis solicitudes de préstamo",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),

          // HEADER DE LA TABLA
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Herramienta",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Cant.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Estado",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Fecha sol.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Se entregó el",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CUERPO DE LA TABLA
          StreamBuilder<QuerySnapshot>(
            stream: _requestsRef
                .where('employeeName', isEqualTo: _nameCtrl.text)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("Error al cargar solicitudes: ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No has realizado solicitudes aún."),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final toolName =
                      (data['toolName'] ?? data['herr'] ?? '') as String;
                  final qty = (data['requestedQty'] ?? 1) as int;
                  final status = (data['status'] ?? 'pendiente') as String;

                  // Fecha de solicitud
                  Timestamp? createdTs;
                  if (data['createdAt'] != null &&
                      data['createdAt'] is Timestamp) {
                    createdTs = data['createdAt'] as Timestamp;
                  }
                  final String fechaSolicitudStr = createdTs != null
                      ? createdTs.toDate().toLocal().toString().substring(0, 10)
                      : '-';

                  // Fecha en que se entregó la herramienta
                  Timestamp? deliveredTs;
                  if (data['deliveredAt'] != null &&
                      data['deliveredAt'] is Timestamp) {
                    deliveredTs = data['deliveredAt'] as Timestamp;
                  }
                  final String fechaEntregoStr = deliveredTs != null
                      ? deliveredTs.toDate().toLocal().toString().substring(
                          0,
                          10,
                        )
                      : '-';

                  // Colores según estado
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

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEFEFEF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            toolName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "$qty",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: border),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            fechaSolicitudStr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            fechaEntregoStr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 28),

          // ===== MIS SOLICITUDES DE ALMACÉN =====
          Text(
            "Mis solicitudes de almacén",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Producto",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Cant.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Estado",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Fecha sol.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: _warehouseRequestsRef
                .where('employeeName', isEqualTo: _nameCtrl.text.trim())
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Error al cargar solicitudes de almacén: ${snapshot.error}",
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No has solicitado productos de almacén aún."),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final String productName =
                      (data['productName'] ?? '') as String;
                  final int qty = (data['quantity'] ?? 0) as int;
                  final String status =
                      (data['status'] ?? 'pendiente') as String;

                  Timestamp? createdTs;
                  if (data['createdAt'] != null &&
                      data['createdAt'] is Timestamp) {
                    createdTs = data['createdAt'] as Timestamp;
                  }
                  final String fechaSolicitudStr = createdTs != null
                      ? _formatWhDate(createdTs)
                      : '-';

                  Color bg;
                  Color border;
                  Color textColor;
                  switch (status) {
                    case 'entregada':
                      bg = const Color(0xFFE9F7EF);
                      border = const Color(0xFF27AE60);
                      textColor = const Color(0xFF1E8449);
                      break;
                    case 'rechazada':
                      bg = const Color(0xFFFFEBEE);
                      border = const Color(0xFFC62828);
                      textColor = const Color(0xFFC62828);
                      break;
                    default:
                      bg = const Color(0xFFFFF9E6);
                      border = const Color(0xFFF1C40F);
                      textColor = const Color(0xFF7D6608);
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEFEFEF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            productName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "$qty",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: border),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            fechaSolicitudStr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 28),

          // ===== MIS REPORTES DE DAÑO =====
          Text(
            "Mis reportes de daño",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),

          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Herramienta",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Tipo de daño",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Estado",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Fecha rep.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "Notas",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          StreamBuilder<QuerySnapshot>(
            stream: _reportsRef
                .where('employeeName', isEqualTo: _nameCtrl.text.trim())
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("Error al cargar reportes: ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No tienes reportes de daño registrados."),
                );
              }

              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final ad =
                      (a['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bd =
                      (b['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bd.compareTo(ad);
                });

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final toolName = (data['toolName'] ?? '') as String;
                  final damageType = (data['damageType'] ?? '') as String;
                  final status = (data['status'] ?? 'pendiente') as String;
                  final notes = (data['notes'] ?? '') as String;

                  Timestamp? createdTs;
                  if (data['createdAt'] != null &&
                      data['createdAt'] is Timestamp) {
                    createdTs = data['createdAt'] as Timestamp;
                  }
                  final fechaRep = createdTs != null
                      ? createdTs.toDate().toLocal().toString().substring(0, 10)
                      : '-';

                  Color bg;
                  Color border;
                  Color textColor;
                  if (status == 'resuelto') {
                    bg = const Color(0xFFE9F7EF);
                    border = const Color(0xFF27AE60);
                    textColor = const Color(0xFF1E8449);
                  } else {
                    bg = const Color(0xFFFFF9E6);
                    border = const Color(0xFFF1C40F);
                    textColor = const Color(0xFF7D6608);
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEFEFEF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            toolName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            damageType,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: border),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            fechaRep,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            notes.isEmpty
                                ? "-"
                                : (notes.length > 40
                                      ? "${notes.substring(0, 40)}..."
                                      : notes),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 28),

          // ===== MI AGENDA =====
          Text(
            "Mi agenda",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),

          // Header tabla
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Fecha / hora",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Tipo",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "Cliente / Proyecto",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Estado",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_currentUserId == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Cargando agenda..."),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: _activitiesRef
                  .where('userId', isEqualTo: _currentUserId)
                  .orderBy('dueAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("Error al cargar agenda: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No tienes actividades registradas."),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final String type = (data['type'] ?? '') as String;
                    final String status =
                        (data['status'] ?? 'pendiente') as String;
                    final String clientName =
                        (data['clientName'] ?? '') as String;
                    final String projectName =
                        (data['projectName'] ?? '') as String;

                    final Timestamp? dueTs = data['dueAt'] as Timestamp?;
                    final String fecha = _formatActivityDate(dueTs);

                    String destino = clientName;
                    if (projectName.isNotEmpty) {
                      destino = clientName.isEmpty
                          ? projectName
                          : "$clientName - $projectName";
                    }
                    if (destino.isEmpty) destino = "—";

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEFEFEF)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              fecha,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              type.isEmpty ? '-' : capitalize(type),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              destino,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: border),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
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

          const SizedBox(height: 28),

          // ===== HERRAMIENTAS DISPONIBLES =====
          Text(
            "Herramientas disponibles",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Herramienta",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Stock disp.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Stock total",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _toolsRef.orderBy('herr').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No hay herramientas registradas."),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['herr'] ?? '') as String;
                  final int stockTotal = (data['stockTotal'] ?? 0) as int;
                  final int stockDisp =
                      (data['stockDisponible'] ?? stockTotal) as int;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEFEFEF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text(name)),
                        Expanded(flex: 3, child: Text("$stockDisp")),
                        Expanded(flex: 3, child: Text("$stockTotal")),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 28),

          // ===== SOLICITAR HERRAMIENTA =====
          Text(
            "Solicitar nueva herramienta",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3D9C8)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selecciona una herramienta disponible y la cantidad a solicitar.\n"
                  "La solicitud será enviada al administrador.",
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: _toolsRef
                      .where('stockDisponible', isGreaterThan: 0)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "No hay herramientas disponibles por ahora.",
                      );
                    }

                    final docs = snapshot.data!.docs;

                    // Si no hay seleccionada aún, elegimos la primera
                    if (_selectedToolId == null) {
                      final first = docs.first;
                      final d = first.data() as Map<String, dynamic>;
                      _selectedToolId = first.id;
                      _selectedToolName = d['herr'] ?? '';
                      _selectedToolDisponible =
                          (d['stockDisponible'] ?? d['stockTotal'] ?? 0) as int;
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedToolId,
                            items: docs.map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              final id = doc.id;
                              final name = d['herr'] ?? '';
                              final disp =
                                  (d['stockDisponible'] ?? d['stockTotal'] ?? 0)
                                      as int;
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  '$name (disp: $disp)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final selectedDoc = docs.firstWhere(
                                (e) => e.id == value,
                              );
                              final d =
                                  selectedDoc.data() as Map<String, dynamic>;
                              setState(() {
                                _selectedToolId = value;
                                _selectedToolName = d['herr'] ?? '';
                                _selectedToolDisponible =
                                    (d['stockDisponible'] ??
                                            d['stockTotal'] ??
                                            0)
                                        as int;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Cantidad",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Disponible: $_selectedToolDisponible",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _enviarSolicitud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      "Enviar solicitud",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ===== PRODUCTOS DE ALMACÉN DISPONIBLES =====
          Text(
            "Productos de almacén disponibles",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Producto",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Cant. disp.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "Ubicación",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: _warehouseRef.orderBy('product').snapshots(),
            builder: (context, snapshot) {
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
                  final String product = (data['product'] ?? '') as String;
                  final int qty = (data['quantity'] ?? 0) as int;
                  final String location = (data['location'] ?? '') as String;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEFEFEF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text(product)),
                        Expanded(flex: 2, child: Text("$qty")),
                        Expanded(
                          flex: 4,
                          child: Text(location.isEmpty ? "—" : location),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          // ===== SOLICITAR PRODUCTO DE ALMACÉN =====
          Text(
            "Solicitar producto de almacén",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: brandOrange,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3D9C8)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selecciona un producto disponible y la cantidad a solicitar.\n"
                  "La solicitud será enviada al administrador.",
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: _warehouseRef
                      .where('quantity', isGreaterThan: 0)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "No hay productos disponibles por ahora.",
                      );
                    }

                    final docs = snapshot.data!.docs;

                    // Si no hay seleccionado, tomamos primero
                    if (_selectedWhProductId == null) {
                      final first = docs.first;
                      final d = first.data() as Map<String, dynamic>;
                      _selectedWhProductId = first.id;
                      _selectedWhProductName = d['product'] ?? '';
                      _selectedWhDisponible = (d['quantity'] ?? 0) as int;
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedWhProductId,
                            items: docs.map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              final id = doc.id;
                              final name = d['product'] ?? '';
                              final disp = (d['quantity'] ?? 0) as int;
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  '$name (disp: $disp)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final selectedDoc = docs.firstWhere(
                                (e) => e.id == value,
                              );
                              final d =
                                  selectedDoc.data() as Map<String, dynamic>;
                              setState(() {
                                _selectedWhProductId = value;
                                _selectedWhProductName = d['product'] ?? '';
                                _selectedWhDisponible =
                                    (d['quantity'] ?? 0) as int;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _whQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Cantidad",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Disponible: $_selectedWhDisponible",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _enviarSolicitudAlmacen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      "Enviar solicitud",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

  // =================== SOLICITUD HERRAMIENTA ===================
  Future<void> _enviarSolicitud() async {
    if (_selectedToolId == null || _selectedToolName == null) {
      _showSnack("Selecciona una herramienta.");
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      _showSnack("Ingresa una cantidad válida.");
      return;
    }
    if (qty > _selectedToolDisponible) {
      _showSnack("No hay stock suficiente para esa cantidad.");
      return;
    }

    try {
      await _requestsRef.add({
        "toolId": _selectedToolId,
        "toolName": _selectedToolName,
        "employeeName": _nameCtrl.text.trim(),
        "employeeId": _currentUserId ?? '',
        "employeeEmail": _currentUserEmail ?? '',
        "requestedQty": qty,
        "status": "pendiente",
        "createdAt": FieldValue.serverTimestamp(),
      });

      _showSnack("Solicitud enviada al administrador.");
      _qtyCtrl.text = "1";
    } catch (e) {
      debugPrint("🔥 Error al enviar la solicitud: $e");
      _showSnack("Error al enviar la solicitud. Revisa la consola.");
    }
  }

  // =================== SOLICITUD PRODUCTO ALMACÉN ===================
  Future<void> _enviarSolicitudAlmacen() async {
    if (_selectedWhProductId == null || _selectedWhProductName == null) {
      _showSnack("Selecciona un producto de almacén.");
      return;
    }

    final qty = int.tryParse(_whQtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      _showSnack("Ingresa una cantidad válida.");
      return;
    }
    if (qty > _selectedWhDisponible) {
      _showSnack("No hay stock suficiente en almacén para esa cantidad.");
      return;
    }

    try {
      await _warehouseRequestsRef.add({
        "productId": _selectedWhProductId,
        "productName": _selectedWhProductName,
        "employeeName": _nameCtrl.text.trim(),
        "employeeId": _currentUserId ?? '',
        "employeeEmail": _currentUserEmail ?? '',
        "quantity": qty,
        "status": "pendiente",
        "createdAt": FieldValue.serverTimestamp(),
      });

      _showSnack("Solicitud de almacén enviada al administrador.");
      _whQtyCtrl.text = "1";
    } catch (e) {
      debugPrint("🔥 Error al enviar solicitud de almacén: $e");
      _showSnack("Error al enviar la solicitud de almacén. Revisa la consola.");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// =================== WIDGETS AUXILIARES ===================
class _InfoRow extends StatelessWidget {
  final String title, value;
  const _InfoRow({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEDEDED)),
          ),
          child: Text(value),
        ),
      ],
    );
  }
}

/// =====================================================================
/// ===================== PANTALLA DE CLIMA EMPLEADO =====================
/// =====================================================================

class EmployeeWeatherScreen extends StatefulWidget {
  const EmployeeWeatherScreen({super.key});

  @override
  State<EmployeeWeatherScreen> createState() => _EmployeeWeatherScreenState();
}

class _EmployeeWeatherScreenState extends State<EmployeeWeatherScreen> {
  final Color brandOrange = const Color(0xFFD76728);
  final Color panelBg = const Color(0xFFFFF4EB);
  final Color pageBg = const Color(0xFFFEFAF6);

  final TextEditingController _cityController = TextEditingController();
  ViewState _climaState = ViewState.idle;
  String _climaError = '';
  Map<String, dynamic>? _climaData;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  bool _isValidCity(String input) {
    if (input.isEmpty) return false;
    final validCharacters = RegExp(r'^[a-zA-Z\s,]+$');
    return validCharacters.hasMatch(input);
  }

  Future<void> _fetchWeather() async {
    final city = _cityController.text.trim();

    if (!_isValidCity(city)) {
      setState(() {
        _climaState = ViewState.error;
        _climaError = "Por favor ingresa una ciudad válida (solo letras).";
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _climaState = ViewState.loading;
      _climaError = '';
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
            onTimeout: () {
              throw TimeoutException("La petición tardó demasiado.");
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _climaData = data;
          _climaState = ViewState.success;
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
        _climaState = ViewState.error;
        _climaError = "No hay conexión a internet.";
      });
    } on TimeoutException {
      setState(() {
        _climaState = ViewState.error;
        _climaError = "El servidor tardó mucho en responder.";
      });
    } catch (e) {
      setState(() {
        _climaState = ViewState.error;
        _climaError = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        elevation: 0,
        title: const Text(
          "Clima en obra",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Consulta el clima en tu zona para planear tus jornadas, uso de EPP y prevenir accidentes.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 18),

              // ======= PANEL PRINCIPAL =======
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _PanelCard(
                    bg: panelBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_outlined,
                              color: brandOrange,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Clima en tiempo real",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Ingresa una ciudad para ver la temperatura, humedad y viento actual.",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 14),

                        // BARRA DE BÚSQUEDA
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  hintText: 'Ciudad, País (ej: Querétaro, MX)',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _fetchWeather,
                                    icon: Icon(
                                      Icons.search,
                                      color: brandOrange,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (_) => _fetchWeather(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // CONTENIDO DINÁMICO
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildClimaContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== ESTADOS DE CONTENIDO ========================

  Widget _buildClimaContent() {
    switch (_climaState) {
      case ViewState.idle:
        return const Padding(
          key: ValueKey('c_idle'),
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            "Escribe una ciudad y presiona Enter o el ícono de búsqueda.",
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        );

      case ViewState.loading:
        return Padding(
          key: const ValueKey('c_loading'),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(color: brandOrange)),
        );

      case ViewState.error:
        return _buildClimaErrorCard();

      case ViewState.success:
        return _buildClimaSuccessCard();
    }
  }

  Widget _buildClimaErrorCard() {
    return Container(
      key: const ValueKey('c_error'),
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
                  _climaError,
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

  Widget _buildClimaSuccessCard() {
    if (_climaData == null) {
      return _buildClimaErrorCard();
    }

    final main = _climaData!['main'];
    final weather = _climaData!['weather'][0];
    final wind = _climaData!['wind'];

    final temp = main['temp'].toStringAsFixed(0);
    final feelsLike = main['feels_like'].toStringAsFixed(1);
    final humidity = main['humidity'].toString();
    final windSpeed = wind['speed'].toString();
    final description = weather['description'].toString();
    final city = _climaData!['name'];
    final country = _climaData!['sys']['country'];

    final iconCode = weather['icon'];
    final iconUrl = 'https://openweathermap.org/img/wn/$iconCode@4x.png';

    final timezoneOffset = _climaData!['timezone'] as int;
    final localTime = DateTime.now().toUtc().add(
      Duration(seconds: timezoneOffset),
    );
    final formattedDate = capitalize(
      DateFormat.yMMMMEEEEd('es_MX').format(localTime),
    );
    final formattedTime = DateFormat.jm('es_MX').format(localTime);

    return Container(
      key: const ValueKey('c_success'),
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
                  style: TextStyle(
                    color: brandOrange,
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
                    _climaItemExtra(
                      icon: Icons.water_drop_outlined,
                      value: "$humidity%",
                      label: "Humedad",
                    ),
                    _climaItemExtra(
                      icon: Icons.air,
                      value: "${windSpeed}m/s",
                      label: "Viento",
                    ),
                    _climaItemExtra(
                      icon: Icons.thermostat,
                      value: "$feelsLike°",
                      label: "Sensación",
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

  Widget _climaItemExtra({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: brandOrange, size: 20),
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
}

// PanelCard reutilizable (mismo estilo que admin)
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
