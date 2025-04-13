import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBRcuQ8vTOD63sjJmR7wI_1xSrDvyxud3o",
      appId: "1:1013796660455:android:bdb4990749b81e12b3ae42",
      messagingSenderId: "1013796660455",
      projectId: "projeto-conversor-9e453",
      databaseURL: "https://projeto-conversor-9e453-default-rtdb.firebaseio.com",
      storageBucket: "projeto-conversor-9e453.firebasestorage.app",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro Firebase',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;

  void _verifyPhone() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: "+55${_phoneController.text}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _goToCadastro();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: Duration(seconds: 60),
    );
  }

  void _signInWithOTP() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      await _auth.signInWithCredential(credential);
      _goToCadastro();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao validar OTP")));
    }
  }

  void _goToCadastro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CadastroTela()),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login via OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Número de telefone'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            if (_codeSent)
              TextField(
                controller: _otpController,
                decoration: InputDecoration(labelText: 'Código OTP'),
                keyboardType: TextInputType.number,
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _codeSent ? _signInWithOTP : _verifyPhone,
              child: Text(_codeSent ? 'Verificar Código' : 'Enviar Código'),
            ),
          ],
        ),
      ),
    );
  }
}

class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  _CadastroTelaState createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final _codigoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  void _salvarDados() async {
    final String codigo = _codigoController.text.trim();
    final String descricao = _descricaoController.text.trim();
    final String valor = _valorController.text.trim();

    if (codigo.isEmpty || descricao.isEmpty || valor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Preencha todos os campos.")));
      return;
    }

    try {
      await _database.child('itens').push().set({
        'codigo': codigo,
        'descricao': descricao,
        'valor': valor,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dados salvos com sucesso!")));
      _codigoController.clear();
      _descricaoController.clear();
      _valorController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar os dados.")));
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastro de Itens")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(labelText: "Código"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(labelText: "Descrição"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Valor"),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvarDados,
              child: Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
