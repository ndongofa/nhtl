import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transport.dart';

class TransportService {
  final String baseUrl =
      'https://nhtl-production-5e78.up.railway.app/api/transports';

  Future<Transport?> createTransport(Transport transport) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transport.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return transport;
    } else {
      print('Erreur POST: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<List<Transport>?> getAllTransports() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Transport.fromJson(e)).toList();
      } else {
        print('Erreur GET: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception GET: $e');
      return null;
    }
  }
}
