/// group.t.sol -- tests for group.sol

// Copyright (C) 2015, 2016  Ryan Casey <ryepdx@gmail.com>
// Copyright (C) 2016, 2017  Daniel Brockman <daniel@brockman.se>

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.11;

import "ds-test/test.sol";

import "./group.sol";

contract DSGroupTest is DSTest {
    DSGroupFactory  factory;
    DSGroup         group;
    Dummy           dummy;
    Person          alice;
    Person          bob;
    Person          eve;
    bytes           calldata;

    function setUp() public {
        factory = new DSGroupFactory();
        dummy = new Dummy();
        alice = new Person();
        bob = new Person();
        eve = new Person();

        address[] memory members = new address[](3);
        members[0] = alice;
        members[1] = bob;
        members[2] = this;

        group = factory.newGroup(members, 2, 3 days);
    }

    function test_setup() public {
        assertEq(group.members(0), alice);
        assertEq(group.members(1), bob);
        assertEq(group.members(2), this);

        assert(group.isMember(this));
        assert(group.isMember(alice));
        assert(group.isMember(bob));
        assert(!group.isMember(eve));

        assertEq(group.quorum(), 2);
        assertEq(group.memberCount(), 3);
        assertEq(group.window(), 3 days);
        assertEq(group.actionCount(), 0);

        var (quorum, memberCount, window, actionCount) = group.getInfo();
        assertEq(quorum, 2);
        assertEq(memberCount, 3);
        assertEq(window, 3 days);
        assertEq(actionCount, 0);
    }

    function testFail_unconfirmed() public {
        var id = group.propose(dummy, new bytes(0), 0);
        group.trigger(id);
    }

    function testFail_transfer() public {
        var id = group.propose(dummy, new bytes(0), 123);
        group.confirm(id);
        bob.confirm(group, id);
        group.trigger(id);
    }

    function test_transfer() public {
        group.deposit.value(123)();
        var id = group.propose(dummy, new bytes(0), 123);
        group.confirm(id);
        bob.confirm(group, id);
        group.trigger(id);
        assertEq(address(dummy).balance, 123);
    }

    function test_propose() public {
        assertEq(group.propose(dummy, new bytes(0), 0), 1);
        assertEq(group.actionCount(), 1);
        assertEq(group.target(1), dummy);
        assertEq(group.value(1), 0);
        assertEq(group.deadline(1), now + 3 days);
        assertEq(group.confirmations(1), 0);
        assert(!group.triggered(1));
        assert(!group.expired(1));
        assert(!group.confirmed(1));
        assert(!group.confirmedBy(1, this));
        assert(!group.confirmedBy(1, alice));
        assert(!group.confirmedBy(1, bob));
        assert(!group.confirmedBy(1, eve));
    }

    function test_second_propose() public {
        assertEq(group.propose(dummy, new bytes(0), 0), 1);
        assertEq(group.propose(alice, new bytes(0), 0), 2);
        assertEq(group.actionCount(), 2);
        assertEq(group.target(1), dummy);
        assertEq(group.target(2), alice);
    }

    function test_confirm() public {
        group.propose(dummy, new bytes(0), 0);
        group.confirm(1);
        assertEq(group.confirmations(1), 1);
        assert(group.confirmedBy(1, this));
        assert(!group.confirmedBy(1, alice));
        assert(!group.confirmedBy(1, bob));
        assert(!group.confirmedBy(1, eve));
        assert(!group.confirmed(1));
        assert(!group.triggered(1));
    }

    function test_second_confirm() public {
        group.propose(dummy, new bytes(0), 0);
        group.confirm(1);
        alice.confirm(group, 1);
        assertEq(group.confirmations(1), 2);
        assert(group.confirmedBy(1, this));
        assert(group.confirmedBy(1, alice));
        assert(group.confirmed(1));
        assert(!group.triggered(1));
    }

    function test_third_confirm() public {
        group.propose(dummy, new bytes(0), 0);
        group.confirm(1);
        alice.confirm(group, 1);
        bob.confirm(group, 1);
        assertEq(group.confirmations(1), 3);
        assert(group.confirmedBy(1, bob));
        assert(group.confirmed(1));
        assert(!group.triggered(1));
    }

    function testFail_double_confirm() public {
        group.propose(dummy, new bytes(0), 0);
        group.confirm(1);
        group.confirm(1);
    }

    function testFail_unauthorized_confirm() public {
        group.propose(dummy, new bytes(0), 0);
        eve.confirm(group, 1);
    }

    function testFail_premature_trigger() public {
        group.propose(dummy, new bytes(0), 0);
        group.confirm(1);
        group.trigger(1);
    }

    function test_trigger() public {
        group.propose(dummy, new bytes(0), 0);
        group.confirm(1);
        alice.confirm(group, 1);
        assert(!dummy.fallbackCalled());
        group.trigger(1);
        assert(group.triggered(1));
        assert(dummy.fallbackCalled());
    }

    function test_failed_trigger() public {
        group.propose(dummy, new bytes(0), 0);
        group.confirm(1);
        alice.confirm(group, 1);
        dummy.setFallbackBlocked(true);
        assert(!group.call(bytes4(sha3("trigger(uint256)")), 1));
        assert(!group.triggered(1));
        assert(!dummy.fallbackCalled());
    }

    function test_payment() public {
        group.deposit.value(500)();
        assertEq(address(group).balance, 500);
        assertEq(address(dummy).balance, 0);

        group.propose(dummy, new bytes(0), 70);
        group.confirm(1);
        alice.confirm(group, 1);
        group.trigger(1);
        assertEq(address(dummy).balance, 70);
        assertEq(address(alice).balance, 0);
        assertEq(address(group).balance, 430);

        group.propose(alice, new bytes(0), 430);
        group.confirm(2);
        alice.confirm(group, 2);
        group.trigger(2);
        assertEq(address(dummy).balance, 70);
        assertEq(address(alice).balance, 430);
        assertEq(address(group).balance, 0);
    }

    function testFail_payment() public {
        assert(group.call.value(500)());
        group.propose(dummy, new bytes(0), 501);
        group.confirm(0);
        alice.confirm(group, 0);
        group.trigger(0);
    }

    function test_calldata() public {
        bytes memory calldata = new bytes(4 + 32);
        bytes4 sig = bytes4(sha3("foo(uint256)"));

        calldata[0] = sig[0];
        calldata[1] = sig[1];
        calldata[2] = sig[2];
        calldata[3] = sig[3];
        calldata[4 + 31] = 123;

        group.propose(dummy, calldata, 0);
        group.confirm(1);
        alice.confirm(group, 1);
        group.trigger(1);
        assertEq(dummy.fooArgument(), 123);
    }
}

contract Dummy {
    uint  public  fooArgument;
    uint  public  fooValue;
    bool  public  fallbackBlocked;
    bool  public  fallbackCalled;

    function () payable public {
        if (fallbackBlocked) {
            throw;
        } else {
            fallbackCalled = true;
        }
    }

    function setFallbackBlocked(bool yes) public {
        fallbackBlocked = yes;
    }

    function foo(uint argument) payable public {
        fooArgument  = argument;
        fooValue     = msg.value;
    }
}

contract Person {
    function () payable public {}

    function confirm(DSGroup group, uint id) public {
        group.confirm(id);
    }
}
