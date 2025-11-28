import 'package:flutter/material.dart';
import 'package:obraprivada/screens/Chatbot.dart';

class ChatbotFab extends StatefulWidget {
  const ChatbotFab({super.key});

  @override
  State<ChatbotFab> createState() => _ChatbotFabState();
}

class _ChatbotFabState extends State<ChatbotFab>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  late final AnimationController _controller;
  late final Animation<double> _jumpAnim; // para subir/bajar
  late final Animation<double> _tiltAnim; // para girito

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _jumpAnim = Tween<double>(
      begin: 0.0,
      end: -4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _tiltAnim = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const SizedBox(width: 420, height: 600, child: ChatScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFD76728);
    final isSmall = MediaQuery.of(context).size.width < 500;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Etiqueta “Hablar con GeoBot” ARRIBA
          AnimatedOpacity(
            opacity: _isHovered ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                "Hablar con GeoBot",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          if (_isHovered) const SizedBox(height: 8),

          // Botón redondo con animación en el robot
          SizedBox(
            width: isSmall ? 64 : 72,
            height: isSmall ? 64 : 72,
            child: FloatingActionButton(
              onPressed: () => _openChat(context),
              shape: const CircleBorder(),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD76728), Color(0xFFFFA24C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandOrange.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // cuando está en hover lo hacemos brincar un poquito más
                    final extraJump = _isHovered ? -2.0 : 0.0;

                    return Transform.translate(
                      offset: Offset(0, _jumpAnim.value + extraJump),
                      child: Transform.rotate(
                        angle: _tiltAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // circulito interior
                      Container(
                        width: isSmall ? 44 : 50,
                        height: isSmall ? 44 : 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFF4EB),
                        ),
                      ),

                      // ícono robot animado
                      const Icon(
                        Icons.smart_toy_rounded,
                        size: 28,
                        color: brandOrange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
