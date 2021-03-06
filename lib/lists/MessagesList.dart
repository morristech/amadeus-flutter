import 'package:amadeus/models/MessageModel.dart';

class MessagesList {
  MessageModel _messageSent;
  List<MessageModel> _messages;

  void fromJson(Map jsonMap) {
    _messages = new List<MessageModel>();
    List listMap = jsonMap['messages'];
    listMap.forEach((map) => _messages.add(new MessageModel.fromJson(map)));
    if (jsonMap['message_sent'].toString().length > 2) {
      _messageSent = new MessageModel.fromJson(jsonMap['message_sent']);
    }
  }

  Map toJson() {
    List list = new List();
    _messages.forEach((model) {
      list.add(model.toJson());
    });
    Map<String, dynamic> map = <String, dynamic>{
      'messages': list,
      'message_sent': _messageSent
    };
    return map;
  }

  MessageModel get messageSent => _messageSent;
  set messageSent(MessageModel value) => this._messageSent = value;

  List<MessageModel> get messages => _messages;
  set messages(List<MessageModel> value) => this._messages = value;
}
