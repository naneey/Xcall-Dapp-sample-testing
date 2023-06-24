// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../xcall/interfaces/ICallService.sol";
import "../xcall/interfaces/ICallServiceReceiver.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DAppProxySample is ICallServiceReceiver, Initializable {
    address private callSvc;
    string private callSvcBtpAddr;
    uint256 private lastId;

    string[] public messages;

    struct RollbackData {
        uint256 id;
        bytes rollback;
        uint256 ssn;
    }
    mapping(uint256 => RollbackData) private rollbacks;

    modifier onlyCallService() {
        require(msg.sender == callSvc, "OnlyCallService");
        _;
    }

    function initialize(
        address _callService
    ) public initializer {
        callSvc = _callService;
        callSvcBtpAddr = ICallService(callSvc).getBtpAddress();
    }

    function compareTo(
        string memory _base,
        string memory _value
    ) internal pure returns (bool) {
        if (
            keccak256(abi.encodePacked(_base)) ==
            keccak256(abi.encodePacked(_value))
        ) {
            return true;
        }
        return false;
    }

    function sendMessage(
        string calldata _to,
        bytes calldata _data,
        bytes calldata _rollback,
        bool _partial
    ) external payable {
        if (_rollback.length > 0) {
            uint256 id = ++lastId;
            bytes memory encodedRd = abi.encode(id, _rollback);
            uint256 sn = ICallService(callSvc).sendCallMessage{value:msg.value}(
                _to,
                _data,
                encodedRd
            );
            rollbacks[id] = RollbackData(id, _rollback, sn);
        } else {
            if(_partial){
                uint256 val = msg.value/2;
                bytes memory subData;
                bytes memory datum;
                bytes1 comma = bytes1(',');
                uint256 index;
                bytes memory bytesZero = bytes("\x00");

                for(uint256 i= 0; i < _data.length; i++){
                    if(_data[i] == comma){
                        index=i;
                        subData = extractDataByIndex(_data,0,index);
                        datum=concatenate(subData,bytesZero);
                        MessageDone(datum);
                        ICallService(callSvc).sendCallMessage{value:val}(
                            _to,
                            datum,
                            _rollback
                        );
                    }
                }
                // remaining after the comma
                subData = extractDataByIndex(_data,index+1,_data.length);

                ICallService(callSvc).sendCallMessage{value:val}(
                    _to,
                    subData,
                    _rollback
                );
            }
            else{
                ICallService(callSvc).sendCallMessage{value:msg.value}(
                    _to,
                    _data,
                    _rollback
                );
            }

        }
    }

    function concatenate(bytes x, bytes y) public pure returns (bytes memory) {
        return abi.encodePacked(x, y);
    }

    function extractDataByIndex(bytes memory _data, uint256 startIndex, uint256 endIndex)internal pure returns (bytes memory){
        uint256 length = endIndex - startIndex;
        bytes memory subData = new bytes(length);

        for (uint256 i = 0; i < length; i++) {
            subData[i] = _data[startIndex];
        }

        return subData;
    }
    /**
       @notice Handles the call message received from the source chain.
       @dev Only called from the Call Message Service.
       @param _from The BTP address of the caller on the source chain
       @param _data The calldata delivered from the caller
     */
    function handleCallMessage(
        string calldata _from,
        bytes calldata _data
    ) external override onlyCallService {
        if (compareTo(_from, callSvcBtpAddr)) {
            // handle rollback data here
            // In this example, just compare it with the stored one.
            (uint256 id, bytes memory received) = abi.decode(_data, (uint256, bytes));
            RollbackData memory stored = rollbacks[id];
            require(compareTo(string(received), string(stored.rollback)), "rollbackData mismatch");
            delete rollbacks[id]; // cleanup
            emit RollbackDataReceived(_from, stored.ssn, received);
        } else {
            string memory msgData = string(_data);
            if (compareTo("revertMessage", msgData)) {
                revert("revertFromDApp");
            }
            // normal message delivery
            string memory lastTwoCharacters = substr(msgData, bytes(msgData).length - 2, 2);

            if (keccak256(abi.encodePacked(lastTwoCharacters)) == keccak256(abi.encodePacked("0x0"))) {
                messages.push(msgData);
                emit MessageSaved(msgData);
            } else {
                emit MessageReceived(_from, encodeMessages());
            }
            //            emit MessageReceived(_from, _data);
        }
    }

    function encodeMessages() internal view returns (bytes memory) {
        uint256 messagesLength = messages.length;
        uint256 totalLength = 0;
        bytes[] memory encodedMessages = new bytes[](messagesLength);

        for (uint256 i = 0; i < messagesLength; i++) {
            encodedMessages[i] = bytes(messages[i]);
            totalLength += encodedMessages[i].length;
        }

        bytes memory result = new bytes(totalLength);
        uint256 offset = 0;

        for (uint256 i = 0; i < messagesLength; i++) {
            uint256 messageLength = encodedMessages[i].length;
            for (uint256 j = 0; j < messageLength; j++) {
                result[offset + j] = encodedMessages[i][j];
            }
            offset += messageLength;
        }

        return result;
    }

    function substr(string memory str, uint256 startIndex, uint256 length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex + length <= strBytes.length, "Invalid substring length");

        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = strBytes[startIndex + i];
        }

        return string(result);
    }

    event MessageSaved(string message);
    event MessageDone(bytes message);
    event MessageDoneTWO(bytes message);

    event MessageReceived(
        string _from,
        bytes _data
    );

    event RollbackDataReceived(
        string _from,
        uint256 _ssn,
        bytes _rollback
    );
}
