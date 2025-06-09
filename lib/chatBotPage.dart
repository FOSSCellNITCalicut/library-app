import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:chat_bubbles/message_bars/message_bar.dart';
import 'package:flutter/material.dart';

class ChatBotPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _ChatBotPageState();

}

class _ChatBotPageState extends State<ChatBotPage> {

  var chatList = <Widget>[];

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void handleChatSend(String msg) {
    final sentChat = BubbleNormal(
      text: msg,
      isSender: true,
      color: Colors.purple,
      textStyle: TextStyle(
          fontSize: 18,
          color: Colors.white
      ),
    );

    final responseChat = BubbleNormal(
      text: "nodakke yenu illa backendalli", // TODO get response from backend
      color: Colors.grey.shade300,
      isSender: false,
      textStyle: TextStyle(
        fontSize: 18
      ),
    );

    chatList.add(sentChat);
    chatList.add(SizedBox(height: 8,));
    chatList.add(responseChat);
    chatList.add(SizedBox(height: 8,));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Library chatbot")
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: chatList,
              ),
            ),
          ),
          CustomMessageBar(
            onSend: (msg) {
              setState(() {
                handleChatSend(msg);
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              });
            },
          )
        ],
      )
    );
  }

}

class CustomMessageBar extends MessageBar {
  final TextEditingController _textController = TextEditingController();

  CustomMessageBar({super.onSend});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(28),
                  child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    onChanged: super.onTextChanged,
                    decoration: InputDecoration(
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: IconButton(
                          onPressed: () {
                            if(_textController.text.trim() != '') {
                              if(onSend != null) {
                                onSend!(_textController.text.trim());
                              }
                              _textController.text = '';
                            }
                          },
                          icon: Icon(Icons.send_outlined),
                        ),
                      ),
                        filled: true,
                        hintText: "",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 14.0,
                        ),
                        fillColor: Colors.purple.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none
                        )

                    ),

                  ),
                )
              )
            )
          ],
        ),
      )
    );
  }
}