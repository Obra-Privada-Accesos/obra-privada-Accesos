import 'package:flutter/material.dart';

class InventarioInfoScreen extends StatelessWidget {
  const InventarioInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandOrange = const Color(0xFFD76728);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Inventario de herramientas',
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
                // TITULO PRINCIPAL
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: brandOrange,
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Panel de Inventario',
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
                  'Aquí podrás controlar todas las herramientas registradas en la obra: '
                  'ver su stock total, stock disponible y llevar un mejor control de los préstamos.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 24),

                // CARD 1: QUE SE HACE AQUI
                _InfoCard(
                  icon: Icons.list_alt_outlined,
                  title: '¿Qué puedes hacer en el inventario?',
                  color: brandOrange,
                  children: const [
                    _Bullet(
                      text:
                          'Ver el listado completo de herramientas registradas.',
                    ),
                    _Bullet(
                      text:
                          'Consultar el stock total y el stock disponible de cada herramienta.',
                    ),
                    _Bullet(
                      text:
                          'Detectar rápidamente si una herramienta está por agotarse.',
                    ),
                    _Bullet(
                      text:
                          'Apoyar la toma de decisiones para nuevas compras o reposiciones.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 2: COMO SE ACTUALIZA
                _InfoCard(
                  icon: Icons.sync_alt_outlined,
                  title: '¿Cómo se actualiza el inventario?',
                  color: Colors.teal,
                  children: const [
                    _Bullet(
                      text:
                          'Cuando el administrador aprueba una solicitud de préstamo, '
                          'se descuenta la cantidad del stock disponible.',
                    ),
                    _Bullet(
                      text:
                          'Cuando se marca un préstamo como "Regresó", la herramienta vuelve al stock disponible.',
                    ),
                    _Bullet(
                      text:
                          'El administrador puede ajustar manualmente el stock total en el módulo de Herramientas.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 3: BUENAS PRACTICAS
                _InfoCard(
                  icon: Icons.tips_and_updates_outlined,
                  title: 'Buenas prácticas',
                  color: Colors.indigo,
                  children: const [
                    _Bullet(
                      text:
                          'Registrar todas las herramientas que se usan en la obra (aunque sea una sola).',
                    ),
                    _Bullet(
                      text:
                          'Evitar prestar herramientas sin pasar por el sistema, para que el stock siempre sea real.',
                    ),
                    _Bullet(
                      text:
                          'Revisar el inventario al inicio y al final de la jornada para detectar pérdidas o daños.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // CTA / MENSAJE FINAL
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
