import 'dart:convert';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:readymadeGroceryApp/service/alert-service.dart';
import 'package:readymadeGroceryApp/service/common.dart';

class ApiInterceptor implements InterceptorContract {
  @override
  Future<RequestData> interceptRequest({RequestData data}) async {
    String languageCode, token;
    await Common.getSelectedLanguage().then((code) {
      languageCode = code ?? "";
    });
    await Common.getToken().then((onValue) {
      token = onValue;
    });
    try {
      data.headers['Content-Type'] = 'application/json';
      data.headers['language'] = languageCode;
      data.headers['Authorization'] = 'bearer $token';
    } catch (e) {
      print(e.toString());
    }
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({ResponseData data}) async {
    var errorData = json.decode(data.body);
    print(errorData);
    if (data.statusCode == 400) {
      var msg = '';
      for (int i = 0, l = errorData['errors'].length; i < l; i++) {
        if (l != i + 1) {
          msg += errorData['errors'][i] + "\n";
        } else {
          msg += errorData['errors'][i];
        }
      }
      AlertService().showToast(msg);
      return Future.error('Unexpected error 😢');
    } else if (data.statusCode == 401) {
      await Common.setToken(null);
      await Common.setUserID(null);
      return Future.error('Unexpected error 😢');
    }
    return data;
  }
}
