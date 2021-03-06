/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

import 'dart:async';
import 'dart:convert';
import 'package:mobile_app/config.dart';
import 'package:mobile_app/gql/queries/system_status.dart';
import 'package:mobile_app/gql/queries/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models.dart';

// Depicts the current auth state
enum AuthState {
  loggingIn,
  loggedIn,
  loggingOut,
  loggedOut,
  loginError,
}

/*
Singleton class that helps managing user authentication.
*/
class AuthHelper {
  static String _url = "$endPoint";
  static String _authApi = '$_url/api-token-auth/';
  static String _verifyApi = '$_url/api-token-verify/';
  static String _gql = '$_url/gql/';

  AuthState _authState;
  AuthState get authState => _authState;
  User _user;
  User get user => _user;
  String _lastError;
  String get lastError => _lastError;

  StreamController<AuthState> _streamController = StreamController.broadcast();
  Stream<AuthState> get eventStream => _streamController.stream;

  bool _isInitialized = false;

  Future<AuthState> init() async {
    if (_isInitialized) {
      return _authState;
    }

    _isInitialized = true;
    _setState(AuthState.loggingIn);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("authenticated") ?? false) {
      _user = User(
          prefs.getInt("auth_id"),
          prefs.getString("auth_username"),
          prefs.getString("auth_token"),
          prefs.getBool("wallet_is_initialized"));
    } else {
      _setState(AuthState.loggedOut);
      return _authState;
    }

    String json = jsonEncode({"token": _user.token});
    http.Response response = await http.post(_verifyApi,
        headers: {"Content-Type": "application/json"}, body: json);

    if (response.statusCode == 200) {
      _successfulLogin(response);
    } else {
      _reset(AuthState.loggedOut);
    }

    return _authState;
  }

  void dispose() {
    print("Authhelper.dispose");
    _streamController.close();
  }

  Future<AuthState> register(
      String username, String password, String email) async {
    String vars = jsonEncode(
        {"username": username, "password": password, "email": email});
    var json = jsonEncode({"query": createUser, "variables": vars});

    return http
        .post(_gql, headers: {"Content-Type": "application/json"}, body: json)
        .then((http.Response response) {
      if (response.statusCode == 200) {
        // Wohoo! Registered, now get the login token
        return login(username, password);
      } else {
        print("Error while registering");
      }
    }).catchError((onError) {
      print(onError);
    });
  }

  Future<dynamic> login(String username, String password) async {
    String json = jsonEncode({"username": username, "password": password});
    _setState(AuthState.loggingIn);

    return http
        .post(_authApi,
            headers: {"Content-Type": "application/json"}, body: json)
        .then((response) {
      if (response.statusCode == 400) {
        _reset(AuthState.loggedOut).then((onValue) => _authState);
      } else {
        _successfulLogin(response).then((onValue) => _authState);
      }
    }).catchError((error) {
      print(error);
      _reset(AuthState.loggedOut);
      return _authState;
    });
  }

  void logout() {
    this._reset(AuthState.loggedOut);
  }

  bool isLoggedIn() {
    return _authState == AuthState.loggedIn;
  }

  Future _successfulLogin(http.Response response) async {
    var body = jsonDecode(response.body);

    if (_user == null) {
      bool walletIsInitialized = await isWalletInitialized(body["token"]);
      _user = User(body["user"]['id'], body["user"]['username'], body["token"],
          walletIsInitialized);
    } else {
      _user.token = body["token"];
    }

    _setState(AuthState.loggedIn);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("authenticated", true);
    await prefs.setInt("auth_id", _user.id);
    await prefs.setString('auth_token', _user.token);
    await prefs.setString('auth_username', _user.name);
    await prefs.setBool("wallet_is_initialized", _user.walletIsInitialized);
  }

  Future _reset(AuthState state, {String error = ""}) async {
    _user = User.empty();
    _setState(state);
    _lastError = error;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("authenticated", false);
    await prefs.setInt("auth_id", _user.id);
    await prefs.setString('auth_token', _user.token);
    await prefs.setString('auth_username', _user.name);
    await prefs.setBool("wallet_is_initialized", _user.walletIsInitialized);
  }

  void _setState(AuthState newState) {
    _authState = newState;
    _streamController.add(_authState);
  }

  Future<bool> isWalletInitialized(String token) async {
    var json = jsonEncode({"query": getInfoQuery});
    var authToken = "JWT $token";
    http.Response response = await http.post(_gql,
        headers: {
          "Content-Type": "application/json",
          "Authorization": authToken
        },
        body: json);

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var typename = json["data"]["lnGetInfo"]["__typename"];
      if (typename == "GetInfoSuccess")
        return true;
      else if (typename == "WalletInstanceNotFound")
        return false;
      else if (typename == "ServerError") return false;

      return true;
    } else {
      print("Error while fetching first get info object");
    }

    return false;
  }

  // Singleton stuff
  static final AuthHelper _singleton = AuthHelper._internal();
  factory AuthHelper() {
    return _singleton;
  }
  AuthHelper._internal();
}
