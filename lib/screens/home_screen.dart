import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GeoToolTrack - Home'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Bienvenido a GeoToolTrack',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 5,
              child: ListTile(
                title: Text('Nombre: Juan Pérez'),
                subtitle: Text('ID: EMP-001'),
              ),
            ),
            Card(
              elevation: 5,
              child: ListTile(
                title: Text('Puesto: Administrador'),
                subtitle: Text('Última acción: Visita a cliente'),
              ),
            ),
            SizedBox(height: 20),
            // Botones de navegación
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 214, 159, 78),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text('Ir a Administrador'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/employee');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text('Ir a Empleado'),
            ),
          ],
        ),
      ),
    );
  }
}
