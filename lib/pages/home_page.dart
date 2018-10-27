import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:amadeus/bo/SubjectBO.dart';
import 'package:amadeus/cache/SubjectCacheController.dart';
import 'package:amadeus/cache/TokenCacheController.dart';
import 'package:amadeus/items/SubjectItem.dart';
import 'package:amadeus/localizations.dart';
import 'package:amadeus/models/SubjectModel.dart';
import 'package:amadeus/models/UserModel.dart';
import 'package:amadeus/res/colors.dart';
import 'package:amadeus/response/SubjectResponse.dart';
import 'package:amadeus/response/TokenResponse.dart';
import 'package:amadeus/services/MessagingService.dart';
import 'package:amadeus/utils/DialogUtils.dart';
import 'package:amadeus/utils/LogoutUtils.dart';

class HomePage extends StatefulWidget {
  static String tag = 'home-page';
  final UserModel user;
  final TokenResponse token;
  HomePage({Key key, @required this.user, @required this.token}) : super(key: key);
  @override
  HomePageState createState() => new HomePageState(user, token);
}

enum Choice {logout}

class HomePageState extends State<HomePage> {

  HomePageState(this._user, this._token);

  List<SubjectModel> _headers;
  UserModel _user;

  bool searching = false;

  String filter;
  Text _tvName;
  TokenResponse _token;
  var _ivPhoto;

  FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  MessagingService messagingService = new MessagingService();

  TextEditingController eCtrl = new TextEditingController();
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> checkToken() async {
    if(_token == null) {
      if(await TokenCacheController.hasTokenCache(context)) {
        _token = await TokenCacheController.getTokenCache(context);
        if(_token.isTokenExpired()) {
          _token = await _token.renewToken(context);
          if(_token == null) {
            DialogUtils.dialog(context);
            Logout.goLogin(context);
          }
        }
      } else {
        DialogUtils.dialog(context);
        Logout.goLogin(context);
      }
    } else if(_token.isTokenExpired()) {
      _token = await _token.renewToken(context);
      if(_token == null) {
        DialogUtils.dialog(context);
        Logout.goLogin(context);
      }
    }
  }

  Future<dynamic> onMessageHome(Map<String, dynamic> message) async {
    messagingService.showNotification(message);
    refreshSubjects();
  }

  @override
  initState() {
    loadWidgets();
    messagingService.configure(HomePage.tag);
    searching = false;
    eCtrl.addListener((){
      setState(() {
        filter = eCtrl.text;
      });
    });
    firebaseMessaging.configure(
      onMessage: onMessageHome,
    );
    super.initState();
  }
  @override
  void dispose() {
    eCtrl.dispose();
    super.dispose();
  }

  Widget _chooseAppBar() {
    if (searching) {
      return AppBar(
        title: new TextField(
          autofocus: true,
          style: new TextStyle(color: primaryWhite),
          decoration: new InputDecoration(
            fillColor: primaryWhite,
            hintText: Translations.of(context).text('searchSubject'),
          ),
          controller: eCtrl,
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.cancel),
            onPressed: () {
              eCtrl.clear();
              searching = false;
              setState(() {});
            },
          ),
        ],
      );
    } else {
      return new AppBar(
        title: _tvName,
        leading: new Padding(
          padding: EdgeInsets.fromLTRB(12.0, 6.0, 0.0, 6.0),
          child: new CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: _ivPhoto,
          ),
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.search),
            onPressed: () {
              searching = true;
              setState(() {});
            },
          ),
          new PopupMenuButton<Choice> (
            onSelected: (Choice result) {
              messagingService.cleanAll();
              Logout.goLogin(context);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Choice>>[
              new PopupMenuItem<Choice>(
                value: Choice.logout,
                child: new Text(Translations.of(context).text('actionLogout')),
              ),
            ],
          ),
        ],
      );
    }
  } 

  Future<void> refreshSubjects() async {
    refreshKey.currentState?.show(atTop: false);

    await checkToken();
   
    SubjectResponse subjectResponse = await getSubjects(context);
    if(subjectResponse != null && subjectResponse.success && subjectResponse.number == 1) {
      await SubjectCacheController.setSubjectCache(context, subjectResponse.data);
      setState(() {
        _headers = subjectResponse.data.subjects;
        _headers.sort((a, b) => b.notifications.compareTo(a.notifications));
      });
    }
  }

  Widget _contentHomePage() {
    if(_headers != null) {
      return new Scaffold(
        backgroundColor: primaryBlue,
        appBar: _chooseAppBar(),
        body: new Theme(
          data: new ThemeData(
            hintColor: primaryBlue,
          ),
          child: new RefreshIndicator(
            key: refreshKey,
            onRefresh: refreshSubjects,
            child: new Theme(
              data: Theme.of(context),
              child: new ListView.builder(
                itemCount: _headers.length,
                itemBuilder: (BuildContext context, int index) {
                  if(filter == null || filter == "") {
                    return SubjectItem(_headers[index], this);
                  } else if(_headers[index].name.toLowerCase().contains(filter.toLowerCase())) {
                    return SubjectItem(_headers[index], this);
                  } else {
                    return new Container();
                  }
                },
              ),
            ),
          ),
        ),
      );
    }
    return new Scaffold(
      appBar: new AppBar(),
      backgroundColor: primaryBlue,
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new CircularProgressIndicator(),
            new SizedBox(height: 10.0),
            new Text(Translations.of(context).text('loadingSubjects'), style: new TextStyle(color: Colors.white),)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _contentHomePage();
  }
      
  @protected
  Widget customScaffold(BuildContext context) {
    return new Scaffold(
      backgroundColor: primaryBlue,
      appBar: _chooseAppBar(),
      body: new Theme(
        data: new ThemeData(
          hintColor: primaryBlue,
        ),
        child: new RefreshIndicator(
          key: refreshKey,
          onRefresh: refreshSubjects,
          child: new Theme(
            data: Theme.of(context),
            child: new ListView.builder(
              itemCount: _headers.length,
              itemBuilder: (BuildContext context, int index) {
                if(filter == null || filter == "") {
                  return SubjectItem(_headers[index], this);
                } else if(_headers[index].name.toLowerCase().contains(filter.toLowerCase())) {
                  return SubjectItem(_headers[index], this);
                } else {
                  return new Container();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @protected
  Future<void> loadWidgets() async {
    /// Getting user
    if(_user != null) {
      _tvName = new Text(_user.getDisplayName());
      await checkToken();
      if(_user.imageUrl != null && _user.imageUrl.isNotEmpty) {
        String path = _token.webserverUrl + _user.imageUrl;
        /// TODO - Store image in cache (ImageUtils)
        _ivPhoto = new NetworkImage(path);
      } else {
        _ivPhoto = new Image.asset('images/no_image.jpg');
      }
      /// Getting subjects
      if(await SubjectCacheController.hasSubjectCache(context)) {
        var subjectList = await SubjectCacheController.getSubjectCache(context);
        _headers = subjectList.subjects;
        _headers.sort((a, b) => b.notifications.compareTo(a.notifications));
        setState(() {});
      } else { /// Get subjects on server
        SubjectResponse subjectResponse = await getSubjects(context);
        if(subjectResponse != null && subjectResponse.success && subjectResponse.number == 1) {
          await SubjectCacheController.setSubjectCache(context, subjectResponse.data);
          _headers = subjectResponse.data.subjects;
          _headers.sort((a, b) => b.notifications.compareTo(a.notifications));
          setState(() {});
        } else if(subjectResponse != null && subjectResponse.title != null && subjectResponse.title.isNotEmpty && subjectResponse.message != null && subjectResponse.message.isNotEmpty) {
          DialogUtils.dialog(context, title: subjectResponse.title, message: subjectResponse.message);
        } else {
          DialogUtils.dialog(context);
        }
      }
    } else {
      DialogUtils.dialog(context);
      Logout.goLogin(context);
    }
  }

  @protected
  Future<SubjectResponse> getSubjects(BuildContext context) async {
    try {
      SubjectResponse subjectResponse = await SubjectBO().getSubjects(context, _user);
      return subjectResponse;
    } catch(e) {
      DialogUtils.dialog(context, erro: e.toString());
      print(e);
    }
    return null;
  }
}
