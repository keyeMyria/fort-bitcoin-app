/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

import 'package:mobile_app/gql/types/lnroute.dart';

class LnSendPaymentResult {
  bool hasError = false;
  String paymentError = "";
  String paymentPreimage = "";
  LnRoute paymentRoute;
  LnSendPaymentResult(Map<String, dynamic> data) {
    if (data["paymentError"] != "") {
      paymentError = data["paymentError"];
      hasError = true;
      return;
    }
    paymentPreimage = data["paymentPreimage"];
    paymentRoute = LnRoute(data["paymentRoute"]);
  }
}