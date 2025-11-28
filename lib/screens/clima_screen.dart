import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Helper para poner mayúscula la primera letra (martes -> Martes)
String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// Estados posibles de la UI
enum ViewState { idle, loading, success, error }

class ClimaScreen extends StatefulWidget {
  const ClimaScreen({super.key});

  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}

class _ClimaScreenState extends State<ClimaScreen> {
  final TextEditingController _cityController = TextEditingController();

  // Variables de estado
  ViewState _currentState = ViewState.idle;
  String _errorMessage = '';
  Map<String, dynamic>? _weatherData;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE API ---

  bool _isValidInput(String input) {
    if (input.isEmpty) return false;
    // Solo permitir letras, espacios y comas (ej: "Queretaro, MX")
    final validCharacters = RegExp(r'^[a-zA-Z\s,]+$');
    return validCharacters.hasMatch(input);
  }

  Future<void> _fetchWeather() async {
    final city = _cityController.text.trim();

    if (!_isValidInput(city)) {
      setState(() {
        _currentState = ViewState.error;
        _errorMessage = "Por favor ingresa una ciudad válida (solo letras).";
      });
      return;
    }

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() {
      _currentState = ViewState.loading;
      _errorMessage = '';
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
          _weatherData = data;
          _currentState = ViewState.success;
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
        _currentState = ViewState.error;
        _errorMessage = "No hay conexión a internet.";
      });
    } on TimeoutException {
      setState(() {
        _currentState = ViewState.error;
        _errorMessage = "El servidor tardó mucho en responder.";
      });
    } catch (e) {
      setState(() {
        _currentState = ViewState.error;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  // --- UI EMBEBIDA EN ADMIN (SIN SCAFFOLD NI GRADIENTE) ---

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFD76728);
    const panelBg = Color(0xFFFFF4EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Inicio · Clima en obra",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: brandOrange,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Consulta el clima en tiempo real para planear jornadas, uso de EPP y prevención de riesgos.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 18),

        // Panel central estilo GeoToolTrack
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Container(
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFF3D9C8)),
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
                  // Buscador
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_outlined,
                        color: brandOrange,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Buscar clima por ciudad",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSearchBar(),

                  const SizedBox(height: 16),

                  // Contenido dinámico: idle / loading / success / error
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildDynamicContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Buscador reutilizable
  Widget _buildSearchBar() {
    return TextField(
      controller: _cityController,
      decoration: const InputDecoration(
        hintText: 'Ingresa una ciudad (ej: Querétaro, MX)',
        suffixIcon: Icon(Icons.search),
      ),
      onSubmitted: (_) => _fetchWeather(),
    );
  }

  // Contenido dinámico
  Widget _buildDynamicContent() {
    switch (_currentState) {
      case ViewState.loading:
        return const Padding(
          key: ValueKey('loading'),
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFD76728)),
          ),
        );
      case ViewState.error:
        return _buildErrorState();
      case ViewState.success:
        return _buildSuccessState();
      case ViewState.idle:
      default:
        return const Padding(
          key: ValueKey('idle'),
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Escribe una ciudad y presiona Enter o el ícono de búsqueda para ver el clima.",
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        );
    }
  }

  // ERROR
  Widget _buildErrorState() {
    return Container(
      key: const ValueKey('error'),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 12),
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
                  _errorMessage,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 10),
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

  // ÉXITO – TARJETA HORIZONTAL
  Widget _buildSuccessState() {
    if (_weatherData == null) return _buildErrorState();

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

    // Hora local
    final timezoneOffset = _weatherData!['timezone'] as int;
    final localTime = DateTime.now().toUtc().add(
      Duration(seconds: timezoneOffset),
    );

    final formattedDate = capitalize(
      DateFormat.yMMMMEEEEd('es_MX').format(localTime),
    );
    final formattedTime = DateFormat.jm('es_MX').format(localTime);

    return Container(
      key: const ValueKey('success'),
      margin: const EdgeInsets.only(top: 8),
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
          // LADO IZQUIERDO: fecha, ciudad, icono, descripción
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

          // LADO DERECHO: temperatura + extras
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
                    _itemExtra(
                      Icons.water_drop_outlined,
                      "$humidity%",
                      "Humedad",
                    ),
                    _itemExtra(Icons.air, "${windSpeed}m/s", "Viento"),
                    _itemExtra(Icons.thermostat, "$feelsLike°", "Sensación"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemExtra(IconData icon, String value, String label) {
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
}
