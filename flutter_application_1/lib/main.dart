import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBRcuQ8vTOD63sjJmR7wI_1xSrDvyxud3o",
      appId: "1:1013796660455:android:bdb4990749b81e12b3ae42",
      messagingSenderId: "1013796660455",
      projectId: "projeto-conversor-9e453",
      databaseURL:
          "https://projeto-conversor-9e453-default-rtdb.firebaseio.com",
      storageBucket: "projeto-conversor-9e453.firebasestorage.app",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conversor de Moeda',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ConversaoTela(),
    );
  }
}

class ConversaoTela extends StatefulWidget {
  @override
  _ConversaoTelaState createState() => _ConversaoTelaState();
}

class _ConversaoTelaState extends State<ConversaoTela> {
  final _valorController = TextEditingController();
  String? _moedaOrigem = 'USD';
  String? _moedaDestino = 'BRL';
  String? _resultado;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<String> _moedas = ['USD', 'BRL', 'EUR', 'GBP'];
  Future<void> _conversao() async {
    if (_valorController.text.isNotEmpty) {
      double valor = double.tryParse(_valorController.text) ?? 0.0;

      final taxas = await _database.child('taxas').get();
      var taxasMap = taxas.value as Map<dynamic, dynamic>?;

      if (taxasMap != null) {
        var taxaOrigemDestino = taxasMap[_moedaOrigem]?[_moedaDestino] ?? 0.0;

        setState(() {
          _resultado = (valor * taxaOrigemDestino).toStringAsFixed(2);
        });
      } else {
        setState(() {
          _resultado = 'Erro ao carregar taxas';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversão de Moeda')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Valor'),
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _moedaOrigem,
              onChanged: (value) {
                setState(() {
                  _moedaOrigem = value;
                });
              },
              items:
                  _moedas.map((moeda) {
                    return DropdownMenuItem<String>(
                      value: moeda,
                      child: Text(moeda),
                    );
                  }).toList(),
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _moedaDestino,
              onChanged: (value) {
                setState(() {
                  _moedaDestino = value;
                });
              },
              items:
                  _moedas.map((moeda) {
                    return DropdownMenuItem<String>(
                      value: moeda,
                      child: Text(moeda),
                    );
                  }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _conversao, child: Text('Converter')),
            SizedBox(height: 16),
            if (_resultado != null) Text('Resultado: $_resultado'),
          ],
        ),
      ),
    );
  }
}
