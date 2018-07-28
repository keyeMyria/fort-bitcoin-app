/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

String getSystemStatus = """
query getBlocks {
  systemstatus: getSystemStatus {
    uptime
    cpuLoad
    trafficIn
    trafficOut
    memoryUsed
    memoryTotal
  }
  testnetblocks: getBlockchainInfo(testnet: true) {
    blocks
  }
  mainnetblocks: getBlockchainInfo(testnet: false) {
    blocks
  }
  testnetnetwork: getNetworkInfo(testnet: true) {
    subversion
    connections
    warnings
  }
  mainnetnetwork: getNetworkInfo(testnet: false) {
    subversion
    connections
    warnings
  }
  testnetln: lnGetInfo(testnet: true) {
    alias
    blockHeight
    identityPubkey
    numActiveChannels
    numPeers
    syncedToChain
    testnet
    version
  }
  mainnetln: lnGetInfo(testnet: false) {
    alias
    blockHeight
    identityPubkey
    numActiveChannels
    numPeers
    syncedToChain
    testnet
    version
  }
}
""";