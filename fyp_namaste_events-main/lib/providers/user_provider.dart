import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/model/user_registration_model.dart';

class UserProvider extends ChangeNotifier {
  userData _userdata = userData(
    id: '',
    userName: '',
    email: '',
    token: '',
    phone:'',
    role:'',
    password:'',
  );

  userData get user => _userdata;

  void setUser(String user) {
    _userdata = userData.fromJson(user);
    notifyListeners();
  }

  void setUserFromModel(userData user) {
    _userdata = user;
    notifyListeners();
  }
}
