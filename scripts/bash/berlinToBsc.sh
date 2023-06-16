#!bin/bash

# BERLIN
DAPP_ADDRESS='cxba0099b8912267842787dc0b3e40bf4c736585ee'
XCALL='cxf4958b242a264fc11d7d8d95f79035e35b21c1bb'

# BSC
BXCALL='0x6193c0b12116c4963594761d859571b9950a8686'
BDAPP_ADDRESS='0x3938907c7759323491c737a3f9fb4a20cefecc9e'

pathToKeyStore=/home/aanya/keystores/test.json
tx=/home/aanya/ibriz/xCall/btp2/e2edemo/scripts/bash/tx

echo ">>>> get fee from xcall"
goloop rpc call --to $XCALL \
      --method getFee \
      --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
      --param _net='0x61.bsc' \
      --param _rollback=0x0 | jq -r . | tee tx/xcallFee


echo ">>>>> send message from dapp"

message='74776f636f6e747261637473636f6e6563746564'
goloop rpc sendtx call --to $DAPP_ADDRESS  \
    --method sendMessage \
    --key_store /home/aanya/keystores/test.json \
    --key_password gochain \
    --nid 0x7 \
    --value $(cat $tx/xcallFee) \
    --step_limit 10000000000 \
    --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
    --param _to='btp://0x61.bsc/0x3938907c7759323491c737a3f9fb4a20cefecc9e' \
    --param _data=$message | jq -r . | tee tx/sendDAPPMessage.icon


#rollbackMessage='0x7468697377696c6c62656d79726f6c6c6261636b6d657373616765'
#goloop rpc sendtx call --to $DAPP_ADDRESS  \
#    --method sendMessage \
#    --key_store /home/aanya/keystores/test.json \
#    --key_password gochain \
#    --nid 0x7 \
#    --value $(cat $tx/xcallFee) \
#    --step_limit 10000000000 \
#    --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
#    --param _to='btp://0x61.bsc/0x3938907c7759323491c737a3f9fb4a20cefecc9e' \
#    --param _data=$message \
#    --param _rollback=$rollbackMessage | jq -r . | tee tx/sendDAPPMessage.icon

sleep 4

echo ">>>> verify transaction was success"
goloop rpc --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
txresult $(cat $tx/sendDAPPMessage.icon) | jq -r . | tee tx/CallMessageLog

# extract the sn from the above log in 'CallMessageSent'
#sn=459

# search for CallMessage event log on BXCALL with the sn extracted above
# The 'CallMessage' will have reqId use this in method below
reqId=303
echo ">>>>>> executeCall on bsc xCALL with the reqId"
 you can do this from browser
 https://testnet.bscscan.com/address/0x6193c0b12116c4963594761d859571b9950a8686#writeContract

# check 'CallExecuted' on destination chain

# IN case of rollbacks without revert

# check berlin xcall 'ResponseMessage' eventlog
# the first index should be our sn from before
# IN case of rollback with revert

# same as rollback but should include RollbackMessage eventlog

# now executeRollback on berlin xCALL contract with the sn
goloop rpc sendtx call --to cxf4958b242a264fc11d7d8d95f79035e35b21c1bb  \
--method executeRollback \
--key_store /home/aanya/keystores/test.json \
--key_password gochain \
--nid 0x7 \
--step_limit 10000000000 \
--uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
--param _sn=0x198 | jq -r . | tee tx/executeRollback.icon

# verify the rollback data received on berlin dAPP 'RollbackDataReceived'

# verify rollback executed on berlin xCAll 'RollbackExecuted'

#goloop rpc sendtx call --to cxf4958b242a264fc11d7d8d95f79035e35b21c1bb  \
#--method executeCall \
#--key_store /home/aanya/keystores/test.json \
#--key_password gochain \
#--nid 0x7 \
#--step_limit 10000000000 \
#--uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
#--param _reqId=0x132 | jq -r . | tee tx/excuteCall.icon


