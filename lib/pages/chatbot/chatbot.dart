import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'package:kalpaniksaathi/models/messages.dart';
import 'package:kalpaniksaathi/repository/data_repository.dart';
import 'package:kalpaniksaathi/services/auth.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final List<types.Message> _messages = [];
  final _user = const types.User(id: 'User');
  final _bot = const types.User(id: 'Bot');
  final DataRepository repository = DataRepository();
  final AuthService auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _loadMessages() async {
    final String userId = auth.getUser().uid.toString();
    final QuerySnapshot<Map<String, dynamic>> msgDb = await repository
        .getMessages(userId) as QuerySnapshot<Map<String, dynamic>>;

    msgDb.docs.forEach((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Messages postdata = Messages.fromSnapshot(doc);

      final textMessage = types.TextMessage(
        author: postdata.author == 'User' ? _user : _bot,
        createdAt: postdata.createdAt,
        id: postdata.id.toString(),
        text: postdata.text.toString(),
      );

      _addMessage(textMessage);
    });

    // final response = await rootBundle.loadString('assets/messages.json');
    // final messages = (jsonDecode(response) as List)
    //     .map((dynamic e) => types.Message.fromJson(e as Map<String, dynamic>))
    //     .toList();
    // setState(() {
    //   _messages = messages;
    // });
  }

  void _handleMessageTap(types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    //send message to db here
    final messageDB = Messages(
        author: 'User',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: auth.getUser().uid.toString(),
        seen: 'false',
        text: message.text,
        type: 'text');

    repository.addMessage(messageDB);

    //send message to rasa here

    final queryParameters = {
      'message': message.text,
      // 'sender': 'Roshan',
    };
    const String apiUri =
        'https://rasa-server-rsnpj.cloud.okteto.net/webhooks/rest/webhook/';

    // final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    final response =
        await http.post(Uri.parse(apiUri), body: json.encode(queryParameters));

    if (response.body.toString().contains('[')) {
      final responseBody = json.decode(response.body) as List;

      for (int i = 0; i < responseBody.length; i++) {
        final responseJson = json.decode(response.body)[i]['text'].toString();

        final botReply = types.TextMessage(
          author: _bot,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: responseJson,
        );

        _addMessage(botReply);

        final messageBotDB = Messages(
            author: 'Bot',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: auth.getUser().uid.toString(),
            seen: 'false',
            text: responseJson,
            type: 'text');

        repository.addMessage(messageBotDB);
      }
    } else {
      final responseJson = json.decode(response.body)[0]['text'].toString();

      final botReply = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: responseJson,
      );

      _addMessage(botReply);

      final messageBotDB = Messages(
          author: 'Bot',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: auth.getUser().uid.toString(),
          seen: 'false',
          text: responseJson,
          type: 'text');

      repository.addMessage(messageBotDB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themedata = Theme.of(context).primaryColor;
    print(themedata == Color(0xffffffff));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
          child: Chat(
            // showUserAvatars: true,
            theme: DefaultChatTheme(
                secondaryColor: Color(0xff5e2d7a),
                primaryColor: Colors.deepPurple.shade800,
                sentMessageBodyTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                receivedMessageBodyTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                inputBackgroundColor:
                    Theme.of(context).primaryColor == const Color(0xffffffff)
                        ? Colors.white30
                        // : const Color.fromRGBO(43, 10, 69, 0.9),
                        : Colors.deepPurple.shade900,
                // inputTextStyle: TextStyle(color: Colors.black),
                inputBorderRadius: BorderRadius.circular(10),
                inputTextStyle: const TextStyle(
                    // fontFamily: 'Schoolbell'
                    ),
                inputPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                sendButtonIcon: const Icon(
                  AntDesign.right,
                  color: Colors.white,
                ),
                deliveredIcon: const Icon(
                  AntDesign.check,
                  color: Colors.white,
                )),
            messages: _messages,
            // onAttachmentPressed: _handleAtachmentPressed,
            onMessageTap: _handleMessageTap,
            onPreviewDataFetched: _handlePreviewDataFetched,
            onSendPressed: _handleSendPressed,
            user: _user,
          ),
        ),
      ),
    );
  }
}

  // void _handleAtachmentPressed() {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return SafeArea(
  //         child: SizedBox(
  //           height: 144,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: <Widget>[
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   _handleImageSelection();
  //                 },
  //                 child: const Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Text('Photo'),
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   _handleFileSelection();
  //                 },
  //                 child: const Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Text('File'),
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Text('Cancel'),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }


  //   void _handleFileSelection() async {
  //   final result = await FilePicker.platform.pickFiles(
  //     type: FileType.any,
  //   );

  //   if (result != null && result.files.single.path != null) {
  //     final message = types.FileMessage(
  //       author: _user,
  //       createdAt: DateTime.now().millisecondsSinceEpoch,
  //       id: const Uuid().v4(),
  //       mimeType: lookupMimeType(result.files.single.path!),
  //       name: result.files.single.name,
  //       size: result.files.single.size,
  //       uri: result.files.single.path!,
  //     );

  //     _addMessage(message);
  //   }
  // }

  // void _handleImageSelection() async {
  //   final result = await ImagePicker().pickImage(
  //     imageQuality: 70,
  //     maxWidth: 1440,
  //     source: ImageSource.gallery,
  //   );

  //   if (result != null) {
  //     final bytes = await result.readAsBytes();
  //     final image = await decodeImageFromList(bytes);

  //     final message = types.ImageMessage(
  //       author: _user,
  //       createdAt: DateTime.now().millisecondsSinceEpoch,
  //       height: image.height.toDouble(),
  //       id: const Uuid().v4(),
  //       name: result.name,
  //       size: bytes.length,
  //       uri: result.path,
  //       width: image.width.toDouble(),
  //     );

  //     _addMessage(message);
  //   }
  // }