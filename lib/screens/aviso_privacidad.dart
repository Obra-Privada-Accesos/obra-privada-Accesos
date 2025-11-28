import 'package:flutter/material.dart';

/// Pantalla: Aviso de Privacidad Integral GeoToolTrack
class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E6),
      appBar: AppBar(
        title: const Text(
          'Aviso de Privacidad',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
              constraints: const BoxConstraints(maxWidth: 850),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------- ENCABEZADO COLOR NARANJA -------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.privacy_tip_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Aviso de Privacidad Integral',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'GeoToolTrack · LFPDPPP (México)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ------- CUERPO DEL TEXTO -------
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(height: 6),

                            // Chips/resumen
                            _ChipsRow(),

                            SizedBox(height: 12),
                            Divider(height: 24),

                            _SectionTitle('1. Responsable del tratamiento'),
                            _Paragraph(
                              'El responsable del tratamiento de sus datos personales es GeoToolTrack, '
                              'aplicación destinada a la gestión de herramientas, empleados y registros '
                              'de préstamo en obras privadas.',
                            ),
                            _Paragraph(
                              'Para cualquier duda relacionada con sus datos personales o con este Aviso '
                              'de Privacidad, puede contactarnos en el siguiente correo de privacidad:\n'
                              '• santianzures923@gmail.com',
                            ),

                            _SectionTitle('2. Datos personales que recabamos'),
                            _Paragraph(
                              'Para brindarle nuestros servicios podemos solicitar los siguientes datos '
                              'personales no sensibles:',
                            ),
                            _BulletList(
                              items: [
                                'Nombre(s) y apellidos.',
                                'Correo electrónico.',
                                'Fecha de nacimiento (en caso de que la empresa lo requiera para validar mayoría de edad).',
                                'Dirección completa (solo cuando sea necesaria para fines operativos o administrativos).',
                                'Información de uso básico dentro de la aplicación (por ejemplo, historial de préstamos y movimientos asociados a su cuenta).',
                              ],
                            ),
                            _Paragraph(
                              'En ningún caso se solicitarán datos financieros, datos sensibles de salud, '
                              'ideología, religión u otra categoría especial de datos personales.',
                            ),

                            _SectionTitle('3. Finalidades del tratamiento'),
                            _SubTitle('3.1 Finalidades primarias (necesarias)'),
                            _BulletList(
                              items: [
                                'Crear y administrar su cuenta como empleado o administrador en GeoToolTrack.',
                                'Identificarlo dentro del sistema al registrar, aprobar o consultar préstamos de herramienta.',
                                'Controlar el historial de movimientos de herramientas (salidas y devoluciones).',
                                'En su caso, gestionar envíos o documentación a la dirección proporcionada.',
                                'Verificar la mayoría de edad cuando sea requerido por la organización.',
                              ],
                            ),
                            _Paragraph(
                              'Sin estos datos, GeoToolTrack no podría funcionar correctamente ni brindarle '
                              'el servicio principal de control de herramientas.',
                            ),
                            _SubTitle(
                              '3.2 Finalidades secundarias (opcionales)',
                            ),
                            _Paragraph(
                              'Adicionalmente, podremos utilizar su correo electrónico para:',
                            ),
                            _BulletList(
                              items: [
                                'Enviar avisos informativos sobre mejoras o cambios relevantes en la aplicación.',
                                'Enviar encuestas breves y/o mensajes de satisfacción del servicio.',
                                'Realizar análisis internos y estadísticas de uso para mejorar la experiencia del usuario.',
                              ],
                            ),
                            _Paragraph(
                              'Si no desea que sus datos se utilicen para estas finalidades secundarias, '
                              'puede enviar un correo a santianzures923@gmail.com indicando en el asunto: '
                              '“No deseo recibir comunicaciones secundarias”.',
                            ),

                            _SectionTitle('4. Consentimiento del usuario'),
                            _Paragraph(
                              'Durante el registro en la aplicación, mostramos un resumen de este Aviso de '
                              'Privacidad y un enlace al texto completo. El usuario otorga su consentimiento '
                              'expreso al completar el formulario y marcar la casilla de verificación que indica '
                              'que ha leído y acepta el Aviso de Privacidad y los Términos y Condiciones.',
                            ),
                            _Paragraph(
                              'Sin esta casilla marcada, el registro no se completa, por lo que ningún dato '
                              'se guarda de forma definitiva en el sistema.',
                            ),

                            _SectionTitle('5. Medidas de seguridad'),
                            _Paragraph(
                              'Para proteger sus datos personales aplicamos medidas administrativas, físicas '
                              'y técnicas razonables, tales como:',
                            ),
                            _BulletList(
                              items: [
                                'Uso de protocolos de cifrado SSL/TLS para la transmisión de datos.',
                                'Controles de acceso restringido únicamente a personal autorizado.',
                                'Buenas prácticas de desarrollo y actualización periódica de la plataforma.',
                                'Respaldo controlado de la información y monitoreo de incidentes.',
                              ],
                            ),
                            _Paragraph(
                              'En caso de usar servicios de nube, estos se alojan en proveedores que cuentan '
                              'con medidas de seguridad reconocidas internacionalmente.',
                            ),

                            _SectionTitle(
                              '6. Conservación y eliminación de datos',
                            ),
                            _Paragraph(
                              'Sus datos personales se conservarán únicamente durante el tiempo necesario '
                              'para cumplir con las finalidades descritas, es decir:',
                            ),
                            _BulletList(
                              items: [
                                'Mientras mantenga una cuenta activa en GeoToolTrack.',
                                'Mientras exista alguna relación contractual, administrativa o legal que lo requiera.',
                              ],
                            ),
                            _Paragraph(
                              'Una vez que solicite la cancelación de su cuenta o ya no exista la relación, '
                              'sus datos serán bloqueados y posteriormente eliminados de forma segura, salvo '
                              'que una disposición legal obligue a conservarlos por más tiempo.',
                            ),

                            _SectionTitle(
                              '7. Derechos ARCO (Acceso, Rectificación, Cancelación y Oposición)',
                            ),
                            _Paragraph(
                              'Usted tiene derecho a conocer qué datos personales tenemos de usted, para qué '
                              'los utilizamos y las condiciones del uso que les damos (Acceso). Asimismo, puede '
                              'solicitar la corrección de su información si está desactualizada o es inexacta '
                              '(Rectificación), pedir que se eliminen de nuestros registros (Cancelación) o '
                              'oponerse a su uso para fines específicos (Oposición).',
                            ),
                            _Paragraph(
                              'Gran parte de la información básica podrá consultarla y actualizarla desde la '
                              'sección “Mi Perfil” dentro de la aplicación.',
                            ),
                            _Paragraph(
                              'Para ejercer formalmente sus derechos ARCO, envíe un correo a '
                              'santianzures923@gmail.com indicando:\n'
                              '• Nombre completo.\n'
                              '• Correo con el que se registró.\n'
                              '• Derecho que desea ejercer (acceso, rectificación, cancelación u oposición).\n'
                              '• Descripción clara de la solicitud y, en su caso, documentación de soporte.',
                            ),

                            _SectionTitle(
                              '8. Transferencia de datos personales',
                            ),
                            _Paragraph(
                              'GeoToolTrack no vende ni renta sus datos personales a terceros. Únicamente '
                              'podrán compartirse cuando sea estrictamente necesario para:',
                            ),
                            _BulletList(
                              items: [
                                'Operar la plataforma (por ejemplo, proveedores tecnológicos o de infraestructura).',
                                'Cumplir obligaciones legales o atender requerimientos de autoridad competente.',
                                'En su caso, coordinar servicios de mensajería o logística cuando la empresa lo requiera.',
                              ],
                            ),
                            _Paragraph(
                              'En cualquier transferencia que no sea necesaria para el servicio o no se derive '
                              'de una obligación legal, se solicitará su consentimiento previo.',
                            ),

                            _SectionTitle(
                              '9. Herramientas de análisis y estadísticas',
                            ),
                            _Paragraph(
                              'Podemos utilizar herramientas de analítica que recolectan información de forma '
                              'agregada y anónima (por ejemplo, pantallas visitadas, tiempo de uso, errores '
                              'técnicos) con el único objetivo de mejorar la estabilidad y experiencia de la '
                              'aplicación. Esta información no se utiliza para identificarle de manera directa.',
                            ),

                            _SectionTitle('10. Brechas de seguridad'),
                            _Paragraph(
                              'En caso de que se detecte una vulneración de seguridad que afecte de manera '
                              'significativa sus datos personales, seguiremos el siguiente procedimiento:',
                            ),
                            _BulletList(
                              items: [
                                'Investigación interna del incidente y evaluación del impacto.',
                                'Aplicación inmediata de medidas técnicas y administrativas correctivas.',
                                'Notificación por correo electrónico a la dirección registrada, en un máximo de 72 horas desde que tengamos conocimiento de la brecha.',
                                'Explicación clara de la naturaleza del incidente y recomendaciones para su protección.',
                              ],
                            ),
                            _Paragraph(
                              'Este procedimiento está alineado con las obligaciones de la LFPDPPP en materia '
                              'de seguridad y transparencia.',
                            ),

                            _SectionTitle('11. Cambios al Aviso de Privacidad'),
                            _Paragraph(
                              'GeoToolTrack podrá actualizar este Aviso de Privacidad para cumplir con cambios '
                              'legales, nuevos requerimientos internos o mejoras al servicio. La versión vigente '
                              'siempre estará disponible dentro de la propia aplicación en la sección “Aviso de '
                              'Privacidad”.',
                            ),
                            _Paragraph(
                              'Le recomendamos revisar periódicamente esta sección. Cualquier cambio importante '
                              'en las finalidades o en la forma de manejar sus datos será comunicado de manera '
                              'visible dentro de la aplicación.',
                            ),

                            SizedBox(height: 12),
                            Text(
                              'Última actualización: 22 de octubre de 2025',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
    );
  }
}

/// ---------- Widgets de apoyo para maquetar el texto ----------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 18,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.orange.shade800,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        item,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Chips/resumen arriba del aviso
class _ChipsRow extends StatelessWidget {
  const _ChipsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: const [
        _ChipTag(icon: Icons.gavel_outlined, label: 'LFPDPPP · México'),
        _ChipTag(
          icon: Icons.account_circle_outlined,
          label: 'Responsable: GeoToolTrack',
        ),
        _ChipTag(icon: Icons.verified_user_outlined, label: 'Derechos ARCO'),
      ],
    );
  }
}

class _ChipTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.orange.shade800),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      backgroundColor: const Color(0xFFFFF4E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
