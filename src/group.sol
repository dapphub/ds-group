/// group.sol -- simple m-of-n multisig implementation

// Copyright (C) 2015, 2016  Ryan Casey <ryepdx@gmail.com>
// Copyright (C) 2016, 2017  Daniel Brockman <daniel@brockman.se>

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.11;

import "ds-exec/exec.sol";
import "ds-note/note.sol";

contract DSGroup is DSExec, DSNote {
    address[]  public  members;
    uint       public  quorum;
    uint       public  window;
    uint       public  actionCount;

    mapping (uint => Action)                     public  actions;
    mapping (uint => mapping (address => bool))  public  confirmedBy;
    mapping (address => bool)                    public  isMember;

    // Legacy events
    event Proposed   (uint id, bytes calldata);
    event Confirmed  (uint id, address member);
    event Triggered  (uint id);

    struct Action {
        address  target;
        bytes    calldata;
        uint     value;

        uint     confirmations;
        uint     deadline;
        bool     triggered;
    }

    constructor(
        address[]  members_,
        uint       quorum_,
        uint       window_
    ) public {
        members  = members_;
        quorum   = quorum_;
        window   = window_;

        for (uint i = 0; i < members.length; i++) {
            isMember[members[i]] = true;
        }
    }

    function memberCount() public view returns (uint) {
        return members.length;
    }

    function target(uint id) public view returns (address) {
        return actions[id].target;
    }
    function calldata(uint id) public view returns (bytes) {
        return actions[id].calldata;
    }
    function value(uint id) public view returns (uint) {
        return actions[id].value;
    }

    function confirmations(uint id) public view returns (uint) {
        return actions[id].confirmations;
    }
    function deadline(uint id) public view returns (uint) {
        return actions[id].deadline;
    }
    function triggered(uint id) public view returns (bool) {
        return actions[id].triggered;
    }

    function confirmed(uint id) public view returns (bool) {
        return confirmations(id) >= quorum;
    }
    function expired(uint id) public view returns (bool) {
        return now > deadline(id);
    }

    function deposit() public note payable {
    }

    function propose(
        address  target,
        bytes    calldata,
        uint     value
    ) public onlyMembers note returns (uint id) {
        id = ++actionCount;

        actions[id].target    = target;
        actions[id].calldata  = calldata;
        actions[id].value     = value;
        actions[id].deadline  = now + window;

        emit Proposed(id, calldata);
    }

    function confirm(uint id) public onlyMembers onlyActive(id) note {
        assert(!confirmedBy[id][msg.sender]);

        confirmedBy[id][msg.sender] = true;
        actions[id].confirmations++;

        emit Confirmed(id, msg.sender);
    }

    function trigger(uint id) public onlyMembers onlyActive(id) note {
        assert(confirmed(id));

        actions[id].triggered = true;
        exec(actions[id].target, actions[id].calldata, actions[id].value);

        emit Triggered(id);
    }

    modifier onlyMembers {
        assert(isMember[msg.sender]);
        _;
    }

    modifier onlyActive(uint id) {
        assert(!expired(id));
        assert(!triggered(id));
        _;
    }

    //------------------------------------------------------------------
    // Legacy functions
    //------------------------------------------------------------------

    function getInfo() public view returns (
        uint  quorum_,
        uint  memberCount,
        uint  window_,
        uint  actionCount_
    ) {
        return (quorum, members.length, window, actionCount);
    }

    function getActionStatus(uint id) public view returns (
        uint     confirmations,
        uint     deadline,
        bool     triggered,
        address  target,
        uint     value
    ) {
        return (
            actions[id].confirmations,
            actions[id].deadline,
            actions[id].triggered,
            actions[id].target,
            actions[id].value
        );
    }
}

contract DSGroupFactory is DSNote {
    mapping (address => bool)  public  isGroup;

    function newGroup(
        address[]  members,
        uint       quorum,
        uint       window
    ) public note returns (DSGroup group) {
        group = new DSGroup(members, quorum, window);
        isGroup[group] = true;
    }
}
