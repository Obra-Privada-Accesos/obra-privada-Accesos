import 'package:flutter/material.dart';

class HistorialInfoScreen extends StatelessWidget {
  const HistorialInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandOrange = const Color(0xFFD76728);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Historial de préstamos',
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
                    Icon(Icons.history_outlined, color: brandOrange, size: 32),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Módulo de Historial',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'En esta sección podrás consultar todos los préstamos de herramientas '
                  'que se han realizado en la obra: quién la solicitó, cuándo salió y cuándo regresó.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 24),

                // CARD 1: QUÉ PUEDES VER AQUÍ
                _InfoCard(
                  icon: Icons.playlist_add_check_outlined,
                  title: '¿Qué puedes ver en el historial?',
                  color: brandOrange,
                  children: const [
                    _Bullet(
                      text:
                          'Listado de todos los préstamos realizados por fecha.',
                    ),
                    _Bullet(
                      text:
                          'Nombre de la herramienta y del empleado que la utilizó.',
                    ),
                    _Bullet(
                      text:
                          'Hora de salida, hora de regreso y estado del préstamo (por ejemplo: "Regresó" o "No regresó").',
                    ),
                    _Bullet(
                      text:
                          'Detalle de préstamos aprobados desde solicitudes del sistema.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 2: PARA QUÉ SIRVE
                _InfoCard(
                  icon: Icons.analytics_outlined,
                  title: '¿Para qué sirve este historial?',
                  color: Colors.teal,
                  children: const [
                    _Bullet(
                      text:
                          'Dar seguimiento a qué herramientas se están usando más y con qué frecuencia.',
                    ),
                    _Bullet(
                      text:
                          'Detectar si hay herramientas que se pierden o tardan demasiado en regresar.',
                    ),
                    _Bullet(
                      text:
                          'Apoyar reportes internos sobre uso de equipo y control de activos de la obra.',
                    ),
                    _Bullet(
                      text:
                          'Tener evidencia clara de quién tenía qué herramienta en una fecha específica.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 3: BUENAS PRÁCTICAS
                _InfoCard(
                  icon: Icons.tips_and_updates_outlined,
                  title: 'Buenas prácticas de registro',
                  color: Colors.indigo,
                  children: const [
                    _Bullet(
                      text:
                          'Registrar el regreso de la herramienta en cuanto vuelva, para mantener el historial al día.',
                    ),
                    _Bullet(
                      text:
                          'Evitar prestar herramientas “por fuera” del sistema para no romper la trazabilidad.',
                    ),
                    _Bullet(
                      text:
                          'En caso de pérdida o daño, usar el historial como referencia para revisar quién la tenía asignada.',
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
