import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String openAIApiKey = 'aqui va tu api key de openai';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  // Colores de marca
  final Color brandOrange = const Color(0xFFD76728);
  final Color panelBg = const Color(0xFFFFF4EB);
  final Color pageBg = const Color(0xFFFEFAF6);

  bool _isTyping = false;

  Future<String> _callOpenAI(String userMessage) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAIApiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4.1-mini',
      'messages': [
        {
          'role': 'system',
          'content': '''
Eres un asistente dentro de la app GeoToolTrack.
Respondes SIEMPRE en español, con tono amigable y claro.
Ayudas a trabajadores de construcción a entender:
- Uso de herramientas
- Uso de maquinaria
- Seguridad y equipo de protección personal (EPP)
- Cómo usar la app GeoToolTrack (consultar herramientas, préstamos, etc.)
Si no sabes algo, dilo claramente.
''',
        },
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.6,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final botReply = data['choices'][0]['message']['content'];
      return botReply.toString().trim();
    } else {
      throw Exception(
        'Error OpenAI: ${response.statusCode} - ${response.body}',
      );
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, sender: 'You'));
      _isTyping = true;
    });

    _controller.clear();

    try {
      final botReply = await _callOpenAI(userMessage);

      setState(() {
        _messages.add(ChatMessage(text: botReply, sender: 'Bot'));
      });
    } catch (e) {
      final fallback = _getBotResponse(userMessage);

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "⚠️ No pude conectarme con el modelo de IA, pero aquí va una respuesta básica:\n\n$fallback",
            sender: 'Bot',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  String _getBotResponse(String userMessage) {
    final lowerMsg = userMessage.toLowerCase();

    if (lowerMsg.contains('herramienta')) {
      return 'Puedes consultar las herramientas disponibles en la sección "Inventario" de la app GeoToolTrack.';
    } else if (lowerMsg.contains('maquinaria')) {
      return 'Recuerda siempre seguir las instrucciones de seguridad al operar maquinaria pesada.';
    } else if (lowerMsg.contains('seguridad') ||
        lowerMsg.contains('epp') ||
        lowerMsg.contains('equipo de protección')) {
      return 'Es fundamental usar casco, chaleco reflectante y botas de seguridad en el sitio de construcción.';
    } else if (lowerMsg.contains('geotooltrack') ||
        lowerMsg.contains('app') ||
        lowerMsg.contains('cómo usar')) {
      return 'Para usar GeoToolTrack, inicia sesión y navega por las secciones para gestionar herramientas y reportar actividades.';
    } else {
      return 'Lo siento, no tengo información sobre eso. ¿Puedes preguntar algo relacionado con herramientas, maquinaria, seguridad o la app GeoToolTrack?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: brandOrange,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.construction, color: Colors.orange),
            ),
            const SizedBox(width: 10),
            const Text(
              "GeoBot · Asistente",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: <Widget>[
          // ====== Lista de mensajes ======
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    // burbuja de "escribiendo..."
                    return _buildTypingBubble();
                  }

                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),

          // ====== Caja de texto ======
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Escribe tu duda sobre herramientas, EPP...",
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: brandOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: brandOrange.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isBot = message.sender == 'Bot';

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isBot ? Colors.white : brandOrange,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isBot
                  ? const Radius.circular(4)
                  : const Radius.circular(16),
              bottomRight: isBot
                  ? const Radius.circular(16)
                  : const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBot) ...[
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFFFFF4EB),
                  child: Icon(Icons.smart_toy, size: 14, color: Colors.orange),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isBot ? Colors.black87 : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 4),
              SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 4),
              SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final String sender;

  ChatMessage({required this.text, required this.sender});
}
