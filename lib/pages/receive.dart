/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_app/gql/queries/payments.dart';
import 'package:mobile_app/gql/types/lninvoice.dart';
import 'package:mobile_app/gql/types/lninvoiceresponse.dart';
import 'package:mobile_app/widgets/scale_in_animated_icon.dart';
import 'package:mobile_app/widgets/show_invoice_qr.dart';
import 'package:mobile_app/widgets/simple_metric.dart';

import '../config.dart' as config;

class ReceivePage extends StatefulWidget {
  static IconData icon = Icons.info;
  static String appBarText = "Receive";

  ReceivePage({Key key, this.title}) : super(key: key);

  final String title;

  final Map<String, dynamic> pluginParameters = {};

  @override
  _ReceivePageState createState() => _ReceivePageState();
}

enum _PageStates {
  initial,
  awaiting_new_invoice,
  awaiting_settlement,
  settled,
  show_error
}

class _ReceivePageState extends State<ReceivePage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _memoController = TextEditingController();

  _PageStates _currentState = _PageStates.initial;
  Widget _currentPage;
  GraphQLClient _client;
  LnAddInvoiceResponse _invoice;
  LnInvoice _settledInvoice;
  SocketClient _socketClient;
  String _errorText;

  @override
  void didChangeDependencies() {
    _makeSock();
    super.didChangeDependencies();
  }

  void _makeSock() async {
    _socketClient = await SocketClient.connect(config.endPointWS);

    final dynamic v = {
      'testnet': true,
    };

    _socketClient
        .subscribe(
            SubscriptionRequest("InvoicesSubscription", invoiceSubscription, v))
        .listen((data) {
      var lnAddInvoiceResponse = LnInvoice(data.data["invoiceSubscription"]);
      if (lnAddInvoiceResponse.paymentRequest == _invoice.paymentRequest) {
        setState(() {
          _settledInvoice = lnAddInvoiceResponse;
          _currentState = _PageStates.settled;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    _client = GraphQLProvider.of(context).value;

    switch (_currentState) {
      case _PageStates.initial:
        _currentPage = Scaffold(
          resizeToAvoidBottomPadding: false,
          body: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Add Invoice",
                    style: theme.textTheme.display3,
                  ),
                  TextFormField(
                      autofocus: true,
                      controller: _valueController,
                      decoration:
                          InputDecoration(labelText: 'Invoice value in sats'),
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: false, signed: false),
                      validator: (value) {
                        int sats = int.tryParse(value);

                        if (sats == null || sats <= 0) {
                          return "Must be more than 0";
                        }
                      }),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Optional memo'),
                    controller: _memoController,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: RaisedButton(
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          var v = {
                            "value": int.tryParse(_valueController.value.text),
                            "memo": _memoController.value.text,
                            "testnet": true
                          };

                          _client
                              .query(QueryOptions(
                                  document: addInvoice, variables: v))
                              .then((data) {
                            LnAddInvoiceResponse resp = LnAddInvoiceResponse(
                                data.data["lnAddInvoice"]["response"]);
                            print(resp.paymentRequest);
                            setState(() {
                              _invoice = resp;
                              _currentState = _PageStates.awaiting_settlement;
                            });
                          }).catchError((error) {
                            print(error);
                            setState(() {
                              _errorText = error.toString();
                              _currentState = _PageStates.show_error;
                            });
                          });

                          setState(() {
                            _currentState = _PageStates.awaiting_new_invoice;
                          });
                        }
                      },
                      child: Text('Create Invoice'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;
      case _PageStates.awaiting_new_invoice:
        _currentPage = Padding(
            padding: EdgeInsets.only(top: 50.0),
            child: Center(
                child: Column(children: <Widget>[
              CircularProgressIndicator(),
              Text("Getting Invoice", style: theme.textTheme.display2)
            ])));
        break;
      case _PageStates.awaiting_settlement:
        _currentPage = Padding(
            padding: EdgeInsets.all(25.0),
            child: ShowInvoiceQr(_invoice, _valueController.value.text,
                _memoController.value.text));
        break;
      case _PageStates.settled:
        _currentPage = Column(children: <Widget>[
          ScaleInAnimatedIcon(
            Icons.check_circle_outline,
          ),
          Padding(
              padding: EdgeInsets.only(top: 25.0),
              child: Text(
                "Settled!",
                style: theme.textTheme.display3,
              )),
          Padding(
              padding: EdgeInsets.only(top: 25.0),
              child: Wrap(
                spacing: 50.0,
                runSpacing: 50.0,
                children: <Widget>[
                  SimpleMetricWidget(
                      "Received", _settledInvoice.value.toString(), "tsats"),
                  SimpleMetricWidget("Memo", _settledInvoice.memo)
                ],
              ))
        ]);
        break;
      case _PageStates.show_error:
        _currentPage = Column(
          children: <Widget>[
            ScaleInAnimatedIcon(
              Icons.error_outline,
              color: Colors.redAccent,
            ),
            Text(
              _errorText,
              style: TextStyle(color: Colors.red, fontSize: 25.0),
            )
          ],
        );
        break;
      default:
        _currentPage = Text("Should not see this");
    }

    return _currentPage;
  }
}
