#!bin/bash

# from berlin to havah
BERLIN_XCALL='cxf4958b242a264fc11d7d8d95f79035e35b21c1bb'
BERLIN_DAPP='cxba0099b8912267842787dc0b3e40bf4c736585ee'


HAVAH_XCALL='cx05b5f4e2cb80827d4b53d13549041c66442f327d'
HAVAH_DAPP='cx7ea8a702c4972005f3e9fd718a0f87c44b464538'

tx=../tx

echo "1. SIMPLE MESSAGE TRANSACTION FROM BERLIN TO HAVAH"
echo " get fee from xcall"
goloop rpc call --to $BERLIN_XCALL \
      --method getFee \
      --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
      --param _net='0x111.icon' \
      --param _rollback=0x0 | jq -r . | tee tx/xcallFee

#echo "send message from dapp"
message='0x6265726c696e746f6861766168'
goloop rpc sendtx call --to $BERLIN_DAPP \
--method sendMessage \
--key_store /home/aanya/keystores/test.json \
--key_password Icon@123 \
--nid 0x7 \
--value $(cat tx/xcallFee) \
--step_limit 10000000000 \
--uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
--param _to='btp://0x111.icon/cx7ea8a702c4972005f3e9fd718a0f87c44b464538' \
--param _data=$message | jq -r . | tee tx/sendDAPPMessage.icon

sleep 4

echo "verify the transaction was success"
goloop rpc --uri https://berlin.net.solidwallet.io/api/v3/icon_dex txresult \
$(cat tx/sendDAPPMessage.icon) | jq -r . | tee tx/CallMessageLog

log=$(cat tx/CallMessageLog)
value=$(echo $(cat tx/CallMessageLog) | jq '.eventLogs[] | select(.scoreAddress == "cxf4958b242a264fc11d7d8d95f79035e35b21c1bb") | select(.indexed[] == "CallMessageSent(Address,str,int,int)")')
sn=$(echo $value | jq -r '.indexed[3]')
echo "Here is th _sn no for your message $sn"


# UNCOMMENT
#echo "check eventLog CallMessage with $sn on havah xcall"
#echo "paste the reqId from the eventlog here"
#reqId=
#
#echo "invoke execute call on havah xcall"
#
#goloop rpc sendtx call --to $HAVAH_XCALL \
#--method executeCall \
#--key_store /home/aanya/keystores/keystore.json \
#--key_password gochain \
#--nid 0x111 \
#--step_limit 10000000000 \
#--uri https://btp.vega.havah.io/api/v3/icon_dex \
#--param _reqId=$reqId | jq -r . | tee tx/excuteCall.icon
#
#echo "verify the transaction was success"
#goloop rpc --uri https://btp.vega.havah.io/api/v3/icon_dex txresult \
#$(cat tx/excuteCall.icon) | jq -r . | tee tx/ExecuteCall