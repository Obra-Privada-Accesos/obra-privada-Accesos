import 'package:flutter/material.dart';

class EmpleadosInfoScreen extends StatelessWidget {
  const EmpleadosInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandOrange = const Color(0xFFD76728);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gestión de empleados',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TÍTULO PRINCIPAL
                Row(
                  children: [
                    Icon(Icons.group_outlined, color: brandOrange, size: 32),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Gestión de empleados',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Aquí se concentra la información de todas las personas que trabajan en la obra: '
                  'sus datos básicos, su rol y sus privilegios dentro del sistema GeoToolTrack.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 24),

                // CARD 1: QUÉ PUEDES HACER
                _InfoCard(
                  icon: Icons.badge_outlined,
                  title: '¿Qué puedes hacer en Empleados?',
                  color: brandOrange,
                  children: const [
                    _Bullet(
                      text:
                          'Ver el listado de todos los empleados registrados en la obra.',
                    ),
                    _Bullet(
                      text:
                          'Consultar datos básicos como nombre completo y correo.',
                    ),
                    _Bullet(
                      text:
                          'Asignar el puesto que desempeña cada persona dentro de la obra.',
                    ),
                    _Bullet(
                      text:
                          'Definir si un usuario tendrá privilegios de Administrador o sólo de Empleado.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 2: TIPOS DE PUESTOS
                _InfoCard(
                  icon: Icons.engineering_outlined,
                  title: 'Ejemplos de puestos que puedes asignar',
                  color: Colors.teal,
                  children: const [
                    _Bullet(text: 'Albañil'),
                    _Bullet(text: 'Carpintero'),
                    _Bullet(text: 'Fierrero / Armador'),
                    _Bullet(text: 'Operador de Maquinaria Pesada'),
                    _Bullet(text: 'Electricista'),
                    _Bullet(text: 'Plomero / Fontanero'),
                    _Bullet(text: 'Maestro de Obra'),
                    _Bullet(text: 'Residente de Obra'),
                    _Bullet(text: 'Topógrafo'),
                    _Bullet(text: 'Pintor / Yesero'),
                    _Bullet(text: 'Administrador (acceso completo al sistema)'),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 3: PRIVILEGIOS
                _InfoCard(
                  icon: Icons.security_outlined,
                  title: 'Roles y privilegios en el sistema',
                  color: Colors.indigo,
                  children: const [
                    _Bullet(
                      text:
                          'Empleado: puede iniciar sesión, ver sus préstamos, hacer solicitudes de herramienta y consultar inventario básico.',
                    ),
                    _Bullet(
                      text:
                          'Administrador: además de lo anterior, puede aprobar/rechazar solicitudes, registrar préstamos manuales, '
                          'editar el inventario y administrar proveedores y empleados.',
                    ),
                    _Bullet(
                      text:
                          'Es importante asignar el rol de Administrador solo a personas de confianza (por ejemplo: residente de obra o maestro de obra).',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // MENSAJE FINAL / CTA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3D9C8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------- WIDGETS REUTILIZABLES --------

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13.5)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
