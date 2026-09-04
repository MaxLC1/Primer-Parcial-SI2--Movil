import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ajusta esta IP a tu red local (o localhost si usas un simulador)
  // Para Android Emulator suele ser 10.0.2.2
  static const String baseUrl = 'http://34.230.18.9:8000/api/v1';

  Future<Map<String, dynamic>?> registrarCliente(String nombre, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/seguridad/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_completo': nombre,
        'email': email,
        'password': password,
        'rol_id': 3 // ID 3 = Cliente (según tu DB)
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Error desconocido');
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/seguridad/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Error desconocido');
    }
  }

  // --- PERSISTENCIA Y SESIÓN ---
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Map<String, dynamic> decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String resp = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(resp);
  }

  Future<void> changePassword(int userId, String newPassword) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/seguridad/change-password'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Error al cambiar contraseña');
    }
  }

  // --- CATÁLOGO ---
  Future<List<dynamic>> getProductos() async {
    final response = await http.get(Uri.parse('$baseUrl/catalogo/productos/'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('No se pudo cargar el catálogo');
    }
  }

  // --- VENTAS Y RESERVAS ---
  Future<void> crearReserva(List<dynamic> items) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final decoded = decodeJwt(token);
    final userId = decoded['id']; // Extraído del JWT

    // Construir la estructura VentaCreate
    final body = {
      'sucursal_id': 1, // Sucursal por defecto para el prototipo
      'usuario_id': userId,
      'detalles': items.map((item) => {
        'producto_id': item.productoId,
        'talla_id': item.tallaId,
        'color_id': item.colorId,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
      }).toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/ventas/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Error al crear reserva');
    }
  }
}
