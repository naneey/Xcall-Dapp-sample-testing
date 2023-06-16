!bin/bash

DAPP_ADDRESS='cxba0099b8912267842787dc0b3e40bf4c736585ee'
XCALL='cxf4958b242a264fc11d7d8d95f79035e35b21c1bb'
pathToKeyStore=/home/aanya/keystores/test.json
tx=/home/aanya/ibriz/xCall/btp2/e2edemo/scripts/tx
echo ">>>> get fee from xcall"
goloop rpc call --to $XCALL \
      --method getFee \
      --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
      --param _net='0x61.bsc' \
      --param _rollback=0x0 | jq -r . | tee tx/xcallFee

      # without rollback 8.75ICX

#echo ">>>>> send message from dapp"
goloop rpc sendtx call --to $DAPP_ADDRESS  \
    --method sendMessage \
    --key_store /home/aanya/keystores/test.json \
    --key_password gochain \
    --nid 0x7 \
    --value $(cat $tx/xcallFee) \
    --step_limit 10000000000 \
    --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
    --param _to='btp://0x61.bsc/0x3938907c7759323491c737a3f9fb4a20cefecc9e' \
    --param _data='0x636865636b53756363657373526573706f6e7365' | jq -r . | tee tx/sendDAPPMessage.icon

sleep 5
#--param _rollback='0x546869734973526f6c6c6261636b4d6573736167655f69636f6e305f68617264686174'
# for evm
#DPP ='0x3938907c7759323491c737a3f9fb4a20cefecc9e
# to='btp://0x7.icon/cxba0099b8912267842787dc0b3e40bf4c736585ee'
#7102199646444099

echo ">>>> verify transaction was success"
goloop rpc --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
txresult $(cat $tx/sendDAPPMessage.icon) | jq -r . | tee tx/CallMessageLog

echo ">>>> verify the event log message from the prev transaction"
transaction_data=$(cat $tx/CallMessageLog)
filtered_logs=$(echo "$transaction_data" | jq '.eventLogs[] | select(.scoreAddress == "cxf4958b242a264fc11d7d8d95f79035e35b21c1bb")')

echo ">>>> logs"
eventLogData=$(echo $filtered_logs | jq -r '.indexed[]')
echo $eventLogData

#sn=0x189
# reqId = 0x18f from the same eventlog

echo ">>>> check the CallMessage on destination chain"
#reqId=255



# for evm to jvm

goloop rpc sendtx call --to cxf4958b242a264fc11d7d8d95f79035e35b21c1bb  \
--method executeCall \
--key_store /home/aanya/keystores/test.json \
--key_password gochain \
--nid 0x7 \
--step_limit 10000000000 \
--uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
--param _reqId=0x110
#
#
#sn= 218