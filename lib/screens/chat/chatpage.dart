import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:readymadeGroceryApp/service/auth-service.dart';
import 'package:readymadeGroceryApp/service/chat-service.dart';
import 'package:readymadeGroceryApp/service/constants.dart';
import 'package:readymadeGroceryApp/service/localizations.dart';
import 'package:readymadeGroceryApp/service/sentry-service.dart';
import 'package:readymadeGroceryApp/style/style.dart';
import 'package:readymadeGroceryApp/widgets/loader.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

SentryError sentryError = new SentryError();

class Chat extends StatefulWidget {
  final Map localizedValues, userDetail, chatDetails;
  final String locale;
  Chat(
      {Key key,
      this.locale,
      this.localizedValues,
      this.userDetail,
      this.chatDetails});

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> with TickerProviderStateMixin {
  List chatList = [];
  final ScrollController _scrollController = new ScrollController();
  final TextEditingController _textController = new TextEditingController();
  bool _isWriting = false,
      isChatLoading = false,
      getUserDataLoading = false,
      getStoreDataLoading = false;

  var chatInfo, resInfo, userData, pageNumber = 0, chatDataLimit = 50;
  Timer chatTimer;
  var socket = io.io(Constants.socketUrl, <String, dynamic>{
    'transports': ['websocket']
  });
  @override
  void initState() {
    getUserData();
    fetchRestaurantInfo();
    super.initState();
  }

  getUserData() async {
    if (mounted) {
      setState(() {
        getUserDataLoading = true;
      });
    }
    await LoginService.getUserInfo().then((onValue) {
      try {
        if (onValue['response_code'] == 200 && mounted) {
          setState(() {
            userData = onValue['response_data'];
            socketInt();
          });
        } else {
          if (mounted) {
            setState(() {
              getUserDataLoading = false;
            });
          }
        }
      } catch (error, stackTrace) {
        sentryError.reportError(error, stackTrace);
      }
    }).catchError((error) {
      sentryError.reportError(error, null);
    });
  }

//fetchres info
  fetchRestaurantInfo() async {
    LoginService.getLocationformation().then((response) {
      try {
        if (response['response_code'] == 200 && mounted) {
          setState(() {
            resInfo = response['response_data'];
            getChatData();
            getUserDataLoading = false;
          });
        } else {
          if (mounted) {
            setState(() {
              getUserDataLoading = false;
            });
          }
        }
      } catch (error, stackTrace) {
        sentryError.reportError(error, stackTrace);
      }
    }).catchError((error) {
      sentryError.reportError(error, null);
    });
  }

  //fetchres info
  getChatData() async {
    print("jj");
    if (mounted) {
      setState(() {
        isChatLoading = true;
      });
    }
    ChatService.chatDataMethod(pageNumber, chatDataLimit).then((response) {
      try {
        if (response['response_code'] == 200 && mounted) {
          setState(() {
            chatList.addAll(response['response_data']);
            isChatLoading = false;
          });
        } else {
          if (mounted) {
            setState(() {
              isChatLoading = false;
            });
          }
        }
      } catch (error, stackTrace) {
        sentryError.reportError(error, stackTrace);
      }
    }).catchError((error) {
      sentryError.reportError(error, null);
    });
  }

  socketInt() {
    socket.on('connect', (data) {
      print('connect ');
      setState(() {
        getUserDataLoading = false;
      });
    });

    socket.on('disconnect', (_) {
      print('disconnect');
    });

    socket.on('message-user-${userData['_id']}', (data) {
      if (mounted) {
        setState(() {
          chatList.addAll(data['messages']);
        });
      }
    });
  }

  @override
  void dispose() {
    if (_scrollController != null) _scrollController.dispose();
    socket.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20))),
          title: new Text(
            MyLocalizations.of(context).getLocalizations("CHAT"),
            style: textbarlowSemiBoldBlack(),
          ),
          centerTitle: true,
          backgroundColor: primary),
      body: isChatLoading || getUserDataLoading || getStoreDataLoading
          ? SquareLoader()
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Expanded(
                      child: new ListView.builder(
                        controller: _scrollController,
                        padding: new EdgeInsets.all(8.0),
                        itemCount:
                            chatList.length == null ? 0 : chatList.length,
                        itemBuilder: (BuildContext context, int index) {
                          bool isOwnMessage = false;
                          if (chatList[index]['sentBy'] == 'USER') {
                            isOwnMessage = true;
                          }
                          return isOwnMessage
                              ? _ownMessage(
                                  chatList[index]['message'],
                                )
                              : _message(
                                  chatList[index]['message'],
                                );
                        },
                      ),
                    ),
                    new Divider(height: 1.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                      ),
                      child: new IconTheme(
                        data: new IconThemeData(
                            color: Theme.of(context).accentColor),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: new Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                new Flexible(
                                  child: new TextField(
                                    maxLines: 1,
                                    controller: _textController,
                                    onChanged: (String txt) {
                                      if (mounted) {
                                        setState(() {
                                          _isWriting = txt.length > 0;
                                        });
                                      }
                                    },
                                    onSubmitted: _submitMsg,
                                    decoration: new InputDecoration.collapsed(
                                        hintText: MyLocalizations.of(context)
                                            .getLocalizations(
                                                "ENTER_TEXT_HERE")),
                                  ),
                                ),
                                new Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                  ),
                                  child: new IconButton(
                                    icon: new Icon(
                                      Icons.send,
                                      color: primary,
                                      size: 30,
                                    ),
                                    onPressed: _isWriting
                                        ? () => _submitMsg(_textController.text)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
    );
  }

  Widget _ownMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(
                        top: 12.0, bottom: 14.0, left: 16.0, right: 16.0),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(0),
                          bottomRight: Radius.circular(40),
                          bottomLeft: Radius.circular(40),
                        ),
                        color: primary.withOpacity(0.60)),
                    child: Text(
                      message,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(
                        top: 12.0, bottom: 14.0, left: 16.0, right: 16.0),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                        bottomLeft: Radius.circular(40),
                      ),
                      color: Color(0xFFF0F0F0),
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitMsg(String txt) async {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 100), curve: Curves.easeOut);
    _textController.clear();
    if (mounted) {
      setState(() {
        _isWriting = false;
      });
    }
    var chatInfo = {
      "message": txt,
      "sentBy": 'USER',
      "userName": userData['firstName'],
      "userId": userData['_id'],
      "storeId": resInfo['_id']
    };

    socket.emit('message-user-to-store', chatInfo);

    chatList.add(chatInfo);
  }
}
