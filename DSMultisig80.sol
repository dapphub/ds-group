/// DSMultisig80.sol -- standalone multisig implementation

// Copyright 2016  Nexus Development, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy of the License may be obtained at the following URL:
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity ^0.4.4;

contract DSMultisig80Events {
    event LogPropose    (uint indexed id);
    event LogConfirm    (uint indexed id, address member);
    event LogCancel     (uint indexed id);
    event LogTrigger    (uint indexed id);
    event LogSetComment (uint indexed id);
}

contract DSMultisig80 is DSMultisig80Events {
    function memberCount() constant returns (uint count) {
        return members.length;
    }

    address[]  public  members;
    uint8      public  quorum;
    uint       public  window;

    mapping (address => bool)  public  isMember;

    function DSMultisig80(
        address[] _members,
        uint8     _quorum,
        uint      _window
    ) {
        members  = _members;
        quorum   = _quorum;
        window   = _window;

        assert(memberCount() <= 255);
        assert(memberCount() >= quorum);

        for (uint i = 0; i < memberCount(); i++) {
            isMember[members[i]] = true;
        }
    }

    function actionCount() constant returns (uint count) {
        return target.length;
    }

    address[]  public  target;
    bytes[]    public  calldata;
    uint[]     public  value;

    address[]  public  proposer;
    string[]   public  signature;
    string[]   public  comment;

    uint[]     public  deadline;
    uint8[]    public  confirmations;
    bool[]     public  cancelled;
    bool[]     public  triggered;
    bool[]     public  succeeded;

    mapping (uint => mapping (address => bool))  public  confirmedBy;

    function propose(
        address  _target,
        string   _signature,
        bytes    _calldata,
        uint     _value
    ) returns (uint id) {
        id = actionCount();

        target        .push(_target);
        calldata      .push(_calldata);
        value         .push(_value);

        proposer      .push(msg.sender);
        signature     .push(_signature);

        deadline      .push(now + window);
        confirmations .push(0);
        cancelled     .push(false);
        triggered     .push(false);
        succeeded     .push(false);

        // TODO: If signature given, verify against calldata

        LogPropose(id);
    }

    function () payable {
        // TODO: Associate ether with particular actions
    }

    function callsize(uint id) constant returns (uint) {
        return calldata[id].length;
    }

    function callhash(uint id) constant returns (bytes32) {
        return sha3(calldata[id]);
    }

    function expired(uint id) constant returns (bool) {
        return now >= deadline[id];
    }

    function confirmed(uint id) constant returns (bool) {
        return confirmations[id] >= quorum;
    }

    function propose(
        address target, bytes calldata, uint value
    ) returns (uint id) {
        return propose(target, "", calldata, value);
    }

    function propose(
        address target, string signature, bytes calldata
    ) returns (uint id) {
        return propose(target, signature, calldata, 0);
    }

    function propose(address target, bytes calldata) returns (uint id) {
        return propose(target, calldata, 0);
    }

    function propose(address target, uint value) returns (uint id) {
        return propose(target, "", value);
    }

    function propose(address target) returns (uint id) {
        return propose(target, "", 0);
    }

    function setComment(uint id, string value) {
        assert(isMember[msg.sender]);
        assert(id < actionCount());

        comment[id] = value;

        LogSetComment(id);
    }

    modifier pending(uint id) {
        assert(!cancelled[id]);
        assert(!triggered[id]);
        assert(!expired(id));
        assert(id < actionCount());
        _;
    }

    function cancel(uint id) pending(id) {
        assert(msg.sender == proposer[id]);
        cancelled[id] = true;
    }

    function confirm(uint id) pending(id) {
        assert(isMember[msg.sender]);
        assert(!confirmedBy[id][msg.sender]);

        confirmations[id]++;
        confirmedBy[id][msg.sender] = true;

        LogConfirm(id, msg.sender);
    }

    function trigger(uint id) pending(id) {
        assert(isMember[msg.sender]);
        assert(confirmed(id));
        assert(this.balance >= value[id]);

        triggered[id] = true;
        succeeded[id] = target[id].call.value(value[id])(calldata[id]);

        LogTrigger(id);
    }

    function assert(bool condition) internal {
        if (!condition) {
            throw;
        }
    }
}

contract DSMultisig80Factory {
    address[]                  public  multisigs;
    mapping (address => bool)  public  isMultisig;

    function multisigCount() constant returns (uint) {
        return multisigs.length;
    }

    function newMultisig(
        address[] members, uint8 quorum, uint window
    ) returns (DSMultisig80 result) {
        result = new DSMultisig80(members, quorum, window);
        multisigs.push(result);
        isMultisig[result] = true;
    }
}
