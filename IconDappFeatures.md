## ICON DAPP FEATURES

This section describes the features and test which is supported by the dapp-sample of the repository.

### Single-Hop

This is a simple transaction of "hello world" form berlin to any other chain

### Multi-Hop

This is a transaction where message is sent between two chain but icon chain act as a hub.
For sending message to BSC from SEPOLIA. 
```json
{
   "_to": "btp://0xaa36a7.eth2/<SEPOLIA_DAPP_ADDRESS>",
   "_data": "0x62736353656e647348656c6c6f546f5365706f6c6961",
   "_rollback":"0x0"
}
```

### Rollback

The rollback param contains data with rollback message which is obtained after 
transaction from destination to source chain.

### Two Connected Contracts

The dapp is connected to a dummy contract's method which returns a byte[]. The byte[] is joined with
the message to be sent in transaction.
 ```
{
        byte[] dummyName = (byte[]) Context.call(this.dummyAddress.get(),"nameInBytes","dummyName");

        String data1 = new String(_data);
        String data2 = new String(dummyName);
        return data1+data2;
    }
```

```
 if (readDummyData){
            finalData = concatenateString(_data).getBytes();
 }
```

### Send Multiple Message seperated by delimeter ','

The DAPP creates a list for each message seperated by ',' and sends each item of list separately.

```
    List<byte[]> ff = new ArrayList<>();
    
    String msgData = new String(_data);
    List<String> substrings = new ArrayList<>();
    StringBuilder sb = new StringBuilder();

    char delimiter = ',';
    for (int i = 0; i < msgData.length(); i++) {
        char currentChar = msgData.charAt(i);
        if (currentChar == delimiter){
            substrings.add(sb.toString());
            sb.setLength(0);
        }else {
            sb.append(currentChar);
        }

    }
    substrings.add(sb.toString());
    ff.clear();
    for (String substring: substrings) {
        finalData = substring.getBytes();
        ff.add(finalData);
    }
        
```

### Partial data processing on receiving end
The Dapp receives and processes the received data in chunks and emits `MessageInChunksReceived` eventlog

```
    int numChunk = (msgData.length() + 4)/5;
    for (int i = 0; i < numChunk; i++) {
        int start = i * 5;
        int end = (i + 1) * 5;
    
        if (end > msgData.length()) {
            end = msgData.length();
        }
    
        byte[] chunk = new byte[end - start];
        int chunkIndex = 0;
        for (int j = start; j < end; j++) {
            chunk[chunkIndex] = _data[j];
            chunkIndex++;
        }
    
        finalData.add(chunk);
        MessageInChunksReceived(_from, chunk);

```