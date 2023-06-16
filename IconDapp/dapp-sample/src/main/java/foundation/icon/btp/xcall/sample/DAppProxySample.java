/*
 * Copyright 2022 ICON Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package foundation.icon.btp.xcall.sample;

import foundation.icon.btp.xcall.CallServiceReceiver;
import foundation.icon.score.client.ScoreClient;
import score.Address;
import score.Context;
import score.DictDB;
import score.UserRevertedException;
import score.VarDB;
import score.annotation.EventLog;
import score.annotation.External;
import score.annotation.Optional;
import score.annotation.Payable;
import scorex.util.ArrayList;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.util.List;

@ScoreClient
public class DAppProxySample implements CallServiceReceiver {
    private final XCallProxy xCall;
    private final String callSvcBtpAddr;
    private final VarDB<BigInteger> id = Context.newVarDB("id", BigInteger.class);
    private final VarDB<Address> dummyAddress = Context.newVarDB("dummy_score_address",Address.class);
    private final DictDB<BigInteger, RollbackData> rollbacks = Context.newDictDB("rollbacks", RollbackData.class);

    public DAppProxySample(Address _callService) {
        this.xCall = new XCallProxy(_callService);
        this.callSvcBtpAddr = xCall.getBtpAddress();
    }

    private void onlyCallService() {
        Context.require(Context.getCaller().equals(xCall.address()), "onlyCallService");
    }

    private BigInteger getNextId() {
        BigInteger _id = this.id.getOrDefault(BigInteger.ZERO);
        _id = _id.add(BigInteger.ONE);
        this.id.set(_id);
        return _id;
    }
    @External
    public void setDummyScoreAddress(Address address){
        dummyAddress.set(address);
    }

    private String concatenateString(byte[] _data){
        // call on second contract
        byte[] dummyName = (byte[]) Context.call(this.dummyAddress.get(),"nameInBytes","dummyName");

        String data1 = new String(_data);
        String data2 = new String(dummyName);
        return data1+data2;
    }

    @Payable
    @External
    public void sendMessage(String _to, byte[] _data,boolean readDummyData,
                            @Optional boolean multipleMessage, @Optional byte[] _rollback){
        // use either multipleMessage or readDummmyData
        List<byte[]> ff = new ArrayList<>();
        byte[] finalData = _data;
        ff.add(finalData);

        if (multipleMessage){
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
        }

//        if (readDummyData){
//            ff.clear();
//            finalData = concatenateString(_data).getBytes();
//            ff.add(finalData);
//        }
        int sizeOfMessage = ff.size();

        for (byte[] bytes : ff) {
            _sendMessage(_to, bytes, BigInteger.valueOf(sizeOfMessage), _rollback);
        }
    }

    private void _sendMessage(String _to, byte[] _data,BigInteger size, @Optional byte[] _rollback) {
        if (_rollback != null) {
            // The code below is not actually necessary because the _rollback data is stored on the xCall side,
            // but in this example, it is needed for testing to compare the _rollback data later.
            var id = getNextId();
            Context.println("DAppProxy: store rollback data with id=" + id);
            RollbackData rbData = new RollbackData(id, _rollback);
            var ssn = _sendCallMessage(Context.getValue().divide(size), _to, _data, rbData.toBytes());
            rbData.setSvcSn(ssn);
            rollbacks.set(id, rbData);
        } else {
            // This is for one-way message
            _sendCallMessage(Context.getValue().divide(size), _to, _data, null);
        }
    }

    private BigInteger _sendCallMessage(BigInteger value, String to, byte[] data, byte[] rollback) {
        try {
            return xCall.sendCallMessage(value, to, data, rollback);
        } catch (UserRevertedException e) {
            // propagate the error code to the caller
            Context.revert(e.getCode(), "UserReverted");
            return BigInteger.ZERO; // call flow does not reach here, but make compiler happy
        }
    }

    @Override
    @External
    public void handleCallMessage(String _from, byte[] _data) {
        onlyCallService();
        Context.println("handleCallMessage: from=" + _from);
        List<byte[]> finalData = new ArrayList<>();

        if (callSvcBtpAddr.equals(_from)) {
            // handle rollback data here
            // In this example, just compare it with the stored one.
            RollbackData received = RollbackData.fromBytes(_data);
            var id = received.getId();
            RollbackData stored = rollbacks.get(id);
            Context.require(stored != null, "invalid received id");
            Context.require(received.equals(stored), "rollbackData mismatch");
            rollbacks.set(id, null); // cleanup
            RollbackDataReceived(_from, stored.getSvcSn(), received.getRollback());
            finalData.add(_data);
        } else {
            // normal message delivery
            String msgData = new String(_data);
            // THIS IS TO TEST TRANSFER OF PARTIAL DATA where the data
            // is received and divided into chunks
            boolean partialDataCheck = true;
            if (partialDataCheck){
                // assuming the chunk size is 5
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
                }
                Context.println("handleCallMessage: msgData=" + msgData);
                if ("revertMessage".equals(msgData)) {
                    Context.revert("revertFromDApp");
                }
            }
            Context.println("The compiled data is: " + finalData + "the size is :" + finalData.size());

            // list to array stream
//            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
//            for (byte[] byteArray : finalData) {
//                try {
//                    outputStream.write(byteArray);
//                } catch (Exception e) {
//                    e.printStackTrace();
//                }
//            }
//            byte[] finalByteArray = outputStream.toByteArray();

            MessageReceived(_from, _data);
        }
    }

    @EventLog
    public void MessageInChunksReceived(String _from, byte[] _chunk) {}

    @EventLog
    public void MessageInChunksSent(String _to, byte[] _chunk) {}

    @EventLog
    public void MessageReceived(String _from, byte[] _data) {}

    @EventLog
    public void RollbackDataReceived(String _from, BigInteger _ssn, byte[] _rollback) {}
}
