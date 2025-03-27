import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.name, required this.id});

  final String name;
  final String id;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final socket = WebSocketChannel.connect(Uri.parse('ws://172.17.0.2:8765'));
  final List<types.Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  late types.User otherUser;
  late types.User me;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    me = types.User(
      id: widget.id,
      firstName: widget.name,
    );

    socket.stream.listen((incomingMessage) {
      List<String> parts = incomingMessage.split(' from ');
      String jsonString = parts[0];

      Map<String, dynamic> data = jsonDecode(jsonString);
      String id = data['id'];
      String msg = data['msg'];
      String nick = data['nick'] ?? id;

      if (id != me.id) {
        otherUser = types.User(
          id: id,
          firstName: nick,
        );
        onMessageReceived(msg);
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    });
  }

  // Salva a imagem base64 no armazenamento temporário e retorna o caminho do arquivo
  Future<String> saveBase64Image(String base64String) async {
    final Uint8List bytes = base64Decode(base64String);
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';

    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // Quando recebe uma mensagem, verifica se é uma imagem 
  void onMessageReceived(String message) async {
    types.Message newMessage;

    if (message.startsWith('data:image')) {
      final base64Data = message.split(',')[1];
      final imagePath = await saveBase64Image(base64Data);

      newMessage = types.ImageMessage(
        author: otherUser,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        uri: imagePath, // Caminho local da imagem
        name: 'imagem_recebida.png',
        size: File(imagePath).lengthSync(),
      );
    } else {
      newMessage = types.TextMessage(
        author: otherUser,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    _addMessage(newMessage);
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  // Envia uma mensagem de texto
  void _sendMessageCommon(String text) {
    final textMessage = types.TextMessage(
      author: me,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
    );

    var payload = {
      'id': me.id,
      'msg': text,
      'nick': me.firstName,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    socket.sink.add(json.encode(payload));
    _addMessage(textMessage);
  }

  // Captura e envia uma imagem convertida para base64
  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await image.readAsBytes();

      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
      );

      final base64String = base64Encode(result);
      final base64DataUrl = "data:image/png;base64,$base64String";

      final imageMessage = types.ImageMessage(
        author: me,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uri: image.path, // Envia a URI local para exibição no chat
        name: 'imagem_enviada.png',
        size: result.length,
      );

      var payload = {
        'id': me.id,
        'msg': base64DataUrl,
        'nick': me.firstName,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      socket.sink.add(json.encode(payload));
      _addMessage(imageMessage);
    }
  }

  void _handleSendPressed(types.PartialText message) {
    _sendMessageCommon(message.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seu Chat: ${widget.name}',
            style: TextStyle(
              color: Colors.white,
            )),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _sendImage,
            tooltip: 'Enviar Imagem',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Chat(
              messages: _messages,
              user: me,
              showUserAvatars: true,
              showUserNames: true,
              onSendPressed: _handleSendPressed,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    socket.sink.close();
    super.dispose();
  }
}
