/// DSMultisig80.t.sol -- DSMultisig80 tests

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

import "dapple/test.sol";

import "DSMultisig80.sol";

contract DSMultisig80Test is Test, DSMultisig80Events {
    DSMultisig80Factory  factory;
    DSMultisig80         multisig;
    Person               alice;
    Person               bob;
    Person               eve;
    Dummy                dummy;

    function setUp() {
        address[] memory members  = new address[](3);
        members[0] = this;
        members[1] = alice = new Person();
        members[2] = bob = new Person();
        dummy = new Dummy();
        eve = new Person();
        factory = new DSMultisig80Factory();
        multisig = factory.newMultisig(members, 2, 24 hours);
        foo(123);
    }

    function test_setup() {
        assertEq(multisig.memberCount(), 3);
        assertEq(multisig.members(0), this);
        assertEq(multisig.members(1), alice);
        assertEq(multisig.members(2), bob);
        assertTrue(multisig.isMember(this));
        assertTrue(multisig.isMember(alice));
        assertTrue(multisig.isMember(bob));
        assertFalse(multisig.isMember(eve));
        assertEq(uint(multisig.quorum()), 2);
        assertEq(uint(multisig.window()), 24 hours);
        assertEq(multisig.actionCount(), 0);
    }

    function test_propose() {
        assertEq(multisig.propose(dummy), 0);
        assertEq(multisig.actionCount(), 1);
        assertEq(multisig.target(0), dummy);
        assertEq(multisig.callsize(0), 0);
        assertEq(multisig.value(0), 0);
        assertEq(uint(multisig.deadline(0)), now + 24 hours);
        assertEq(uint(multisig.confirmations(0)), 0);
        assertFalse(multisig.triggered(0));
        assertFalse(multisig.succeeded(0));
        assertFalse(multisig.expired(0));
        assertFalse(multisig.confirmed(0));
        assertFalse(multisig.confirmedBy(0, this));
        assertFalse(multisig.confirmedBy(0, alice));
        assertFalse(multisig.confirmedBy(0, bob));
        assertFalse(multisig.confirmedBy(0, eve));
    }

    function test_second_propose() {
        assertEq(multisig.propose(dummy), 0);
        assertEq(multisig.propose(alice), 1);
        assertEq(multisig.actionCount(), 2);
        assertEq(multisig.target(0), dummy);
        assertEq(multisig.target(1), alice);
    }

    function test_confirm() {
        multisig.propose(dummy);
        multisig.confirm(0);
        assertEq(uint(multisig.confirmations(0)), 1);
        assertTrue(multisig.confirmedBy(0, this));
        assertFalse(multisig.confirmedBy(0, alice));
        assertFalse(multisig.confirmedBy(0, bob));
        assertFalse(multisig.confirmedBy(0, eve));
        assertFalse(multisig.confirmed(0));
        assertFalse(multisig.triggered(0));
        assertFalse(multisig.succeeded(0));
    }

    function test_second_confirm() {
        multisig.propose(dummy);
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        assertEq(uint(multisig.confirmations(0)), 2);
        assertTrue(multisig.confirmedBy(0, this));
        assertTrue(multisig.confirmedBy(0, alice));
        assertTrue(multisig.confirmed(0));
        assertFalse(multisig.triggered(0));
        assertFalse(multisig.succeeded(0));
    }

    function test_third_confirm() {
        multisig.propose(dummy);
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        bob.confirm(multisig, 0);
        assertEq(uint(multisig.confirmations(0)), 3);
        assertTrue(multisig.confirmedBy(0, bob));
        assertTrue(multisig.confirmed(0));
        assertFalse(multisig.triggered(0));
        assertFalse(multisig.succeeded(0));
    }

    function testFail_double_confirm() {
        multisig.propose(dummy);
        multisig.confirm(0);
        multisig.confirm(0);
    }

    function testFail_unauthorized_confirm() {
        multisig.propose(dummy);
        eve.confirm(multisig, 0);
    }

    function testFail_premature_trigger() {
        multisig.propose(dummy);
        multisig.confirm(0);
        multisig.trigger(0);
    }

    function test_trigger() {
        multisig.propose(dummy);
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        assertFalse(dummy.fallbackCalled());
        multisig.trigger(0);
        assertTrue(multisig.triggered(0));
        assertTrue(multisig.succeeded(0));
        assertTrue(dummy.fallbackCalled());
    }

    function test_failed_trigger() {
        multisig.propose(dummy);
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        dummy.setWillFail(true);
        multisig.trigger(0);
        assertTrue(multisig.triggered(0));
        assertFalse(multisig.succeeded(0));
        assertFalse(dummy.fallbackCalled());
    }

    function test_payment() {
        assertTrue(multisig.send(500));
        assertEq(multisig.balance, 500);
        assertEq(dummy.balance, 0);

        multisig.propose(dummy, 70);
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        multisig.trigger(0);
        assertEq(dummy.balance, 70);
        assertEq(alice.balance, 0);
        assertEq(multisig.balance, 430);

        multisig.propose(alice, 430);
        multisig.confirm(1);
        alice.confirm(multisig, 1);
        multisig.trigger(1);
        assertEq(dummy.balance, 70);
        assertEq(alice.balance, 430);
        assertEq(multisig.balance, 0);
    }

    function testFail_payment() {
        assertTrue(multisig.call.value(500)());
        multisig.propose(dummy, 501);
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        multisig.trigger(0);
    }

    bytes expectedData;
    function foo(uint32 argument) { expectedData = msg.data; }

    function test_calldata_implicit() {
        this.foo(123456789);

        expectEventsExact(multisig);
        LogProposed(0);
        LogConfirmed(0, this);
        LogConfirmed(0, alice);
        LogTriggered(0);

        multisig.propose(dummy, expectedData);
        assertEq32(multisig.callhash(0), sha3(expectedData));
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        multisig.trigger(0);
        assertEq(uint(dummy.fooArgument()), 123456789);
    }

    bytes32 expectedHash =
        0x97d8fbf60876829f4c06d6ba83082b4bd94b9de1ac1b71869315afccddc805cc;

    function test_calldata_explicit() {
        bytes memory calldata = new bytes(4 + 32);

        calldata[0] = 0x89;
        calldata[1] = 0xe9;
        calldata[2] = 0x2c;
        calldata[3] = 0xd7;
        calldata[4 + 31] = 123;

        multisig.propose(dummy, calldata);
        assertEq32(multisig.callhash(0), expectedHash);
        multisig.confirm(0);
        alice.confirm(multisig, 0);
        multisig.trigger(0);
        assertEq(uint(dummy.fooArgument()), 123);
    }
}

contract Dummy {
    bool    public  willFail;
    bool    public  fallbackCalled;
    uint32  public  fooArgument;

    function setWillFail(bool value) {
        willFail = value;
    }

    function () payable {
        if (willFail) {
            throw;
        } else {
            fallbackCalled = true;
        }
    }

    function foo(uint32 argument) {
        fooArgument = argument;
    }
}

contract Person {
    function confirm(DSMultisig80 multisig, uint action) {
        multisig.confirm(action);
    }
}
