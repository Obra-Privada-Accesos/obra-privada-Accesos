import 'package:flutter/material.dart';

class SuppliersInfoScreen extends StatelessWidget {
  const SuppliersInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandOrange = const Color(0xFFD76728);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gestión de proveedores',
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
                    Icon(
                      Icons.storefront_outlined,
                      color: brandOrange,
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Módulo de Proveedores',
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
                  'En esta sección se centraliza la información de todos los proveedores '
                  'relacionados con la obra: empresas, contactos, teléfonos y productos que ofrecen. '
                  'Llevar bien este módulo ayuda a que la obra nunca se detenga por falta de material.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 24),

                // CARD 1: ¿QUÉ PUEDES HACER?
                _InfoCard(
                  icon: Icons.contacts_outlined,
                  title: '¿Qué puedes hacer en Proveedores?',
                  color: brandOrange,
                  children: const [
                    _Bullet(
                      text:
                          'Registrar nuevos proveedores con datos básicos: empresa, contacto, teléfono y correo.',
                    ),
                    _Bullet(
                      text:
                          'Guardar qué producto o servicio ofrece cada proveedor (por ejemplo: cemento, acero, maquinaria).',
                    ),
                    _Bullet(
                      text:
                          'Tener a la mano la información de contacto para cotizar o hacer pedidos rápidamente.',
                    ),
                    _Bullet(
                      text:
                          'Organizar la lista de proveedores por tipo de material o servicio.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 2: COMO SE USA EN EL DÍA A DÍA
                _InfoCard(
                  icon: Icons.work_history_outlined,
                  title: '¿Cómo se usa en el día a día?',
                  color: Colors.teal,
                  children: const [
                    _Bullet(
                      text:
                          'Antes de hacer una compra, revisa qué proveedores tienes registrados y compara opciones.',
                    ),
                    _Bullet(
                      text:
                          'Al recibir buen servicio de un proveedor, actualiza las notas para recordar por qué conviene seguir trabajando con él.',
                    ),
                    _Bullet(
                      text:
                          'Si cambian teléfonos, correos o contactos, actualiza el registro para que el equipo no pierda tiempo buscando datos.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 🆕 CARD 3: RELACIÓN CON CLIENTES
                _InfoCard(
                  icon: Icons.handshake_outlined,
                  title: 'Relación entre proveedores y clientes/obra',
                  color: Colors.deepPurple,
                  children: const [
                    _Bullet(
                      text:
                          'Un buen control de proveedores ayuda a cumplir con los tiempos de entrega que se prometen al cliente.',
                    ),
                    _Bullet(
                      text:
                          'Si los materiales llegan a tiempo, se evita retrasar la obra y se mejora la satisfacción del cliente final.',
                    ),
                    _Bullet(
                      text:
                          'Tener varios proveedores de confianza permite reaccionar rápido cuando un cliente pide cambios o aumentos de volumen.',
                    ),
                    _Bullet(
                      text:
                          'La información ordenada de proveedores facilita hacer reportes para la empresa y justificar costos ante el cliente.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CARD 4: BUENAS PRÁCTICAS
                _InfoCard(
                  icon: Icons.tips_and_updates_outlined,
                  title: 'Buenas prácticas con proveedores',
                  color: Colors.indigo,
                  children: const [
                    _Bullet(
                      text:
                          'Registrar al menos dos proveedores por rubro importante (material eléctrico, hierro, cemento, renta de equipo, etc.).',
                    ),
                    _Bullet(
                      text:
                          'Usar el campo de notas para registrar acuerdos importantes: precios especiales, tiempos de entrega, condiciones de crédito.',
                    ),
                    _Bullet(
                      text:
                          'Mantener la información actualizada para evitar llamadas a números viejos o correos que ya no existen.',
                    ),
                    _Bullet(
                      text:
                          'Evaluar periódicamente a los proveedores para conservar a los que ayudan a quedar bien con el cliente.',
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

// ------- WIDGETS REUTILIZABLES (mismos que antes) --------

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
