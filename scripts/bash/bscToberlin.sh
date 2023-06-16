# sepolia testnet

DAPP: 0xe8ad1a4149a619f90973ee49e910085196e0f225
SEPOLIA XCALL:0x9B68bd3a04Ff138CaFfFe6D96Bc330c699F34901

to=btp://0x61.bsc/0x3938907c7759323491c737a3f9fb4a20cefecc9e
1953518843859042




#################################
dapp: 0xfC90D1BEc8d9573049f970cC3cC02b51512be7fa
xcall: 0x9B68bd3a04Ff138CaFfFe6D96Bc330c699F34901

# send message data format
without rollack the fee is :1240959463989361
with rollback is :1953518843859042
btp://0x61.bsc/0x3938907c7759323491c737a3f9fb4a20cefecc9e
data:0x66697273745f74696d655f7365706f6c69615f627363
rollback: 0x7468697377696c6c6265726f6c6c6261636b6d657373616765


sendMessage:
https://sepolia.etherscan.io/tx/0x219906baf0faba134038b09a4e1fd1610b9671b3ec5b506eae8acb0bae17c3e1#eventlog
_sn = 0x43 or 67

wait for eventlog CallMessage on bsc xcall
https://testnet.bscscan.com/tx/0xde1801a7f3a8c81ffb9247596fedc014605ee4f8367f6b87803132e4a1c5f580#eventlog

_reqID 285
executeCall in bsc xcall with this id
https://testnet.bscscan.com/tx/0x02a6f740cc58659ce41c0a54cdb5871ec0544b1238582e4a2d9304564e15bf85
v
data is verified

checking the rollback data
https://sepolia.etherscan.io/tx/0x30fe2694c078f9dd7e8a5e0c5ee268728cefbb5c02046174d8b36287fa89ca63



###########################

goloop rpc sendtx call --to cxba0099b8912267842787dc0b3e40bf4c736585ee  \
    --method setDummyScoreAddress \
    --key_store /home/aanya/keystores/test.json \
    --key_password gochain \
    --nid 0x7 \
    --step_limit 10000000000 \
    --uri https://berlin.net.solidwallet.io/api/v3/icon_dex \
    --param address=cx3ab59895849d113896b66ce7f909f5d9ff5d8bf0