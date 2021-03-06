/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

import 'package:flutter/material.dart';
import 'package:mobile_app/gql/types/lnchannel.dart';

import 'package:mobile_app/widgets/channel_balance.dart';
import 'package:mobile_app/widgets/simple_data_row.dart';

class ChannelDisplay extends StatelessWidget {
  final LnChannel _data;
  ChannelDisplay(this._data);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    var blockHeight = int.parse(_data.chanId) >> 40;

    return Card(
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              width: 5.0,
              height: 150.0,
              color: Colors.green,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "ID: ${_data.chanId}",
                  style: theme.textTheme.headline,
                ),
                Row(
                  children: <Widget>[
                    Expanded(child: Text("Local Balance")),
                    Expanded(
                      child: Text(
                        "Remote Balance",
                        textAlign: TextAlign.right,
                      ),
                    )
                  ],
                ),
                ChannelBalanceWidget(_data.localBalance, _data.remoteBalance),
                SimpleDataRow(left: "Capacity", right: _data.capacity),
                SimpleDataRow(left: "Established", right: blockHeight),
                SimpleDataRow(left: "Sent", right: _data.totalSatoshisSent),
                SimpleDataRow(
                  left: "Received",
                  right: _data.totalSatoshisReceived,
                ),
                SimpleDataRow(
                  left: "Unsettled",
                  right: _data.unsettledBalance,
                ),
                SimpleDataRow(left: "Updates", right: _data.numUpdates)
              ],
            ),
          ),
          Container(
            width: 8.0,
          )
        ],
      ),
    );
  }
}
