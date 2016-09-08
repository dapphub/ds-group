import "dapple/test.sol";

import "multisig_factory.sol";

contract Dummy {
    bool _fail;
    function fail() { _fail = true; }

    bool public fallbackCalled;
    function() { if (_fail) throw; fallbackCalled = true; }

    uint32 public fooArgument;
    function foo(uint32 argument) { fooArgument = argument; }
}

contract Person {
    function confirm(DSBasicMultisig multisig, uint action) {
        multisig.confirm(action);
    }
}

contract DSBasicMultisigTest is Test, DSBasicMultisigEvents {
    DSMultisigFactory factory;
    DSBasicMultisig multisig;
    Person alice;
    Person bob;
    Person eve;
    Dummy dummy;

    function setUp() {
        address[] memory members = new address[](3);
        members[0] = this;
        members[1] = alice = new Person();
        members[2] = bob = new Person();
        dummy = new Dummy();
        eve = new Person();
        factory = new DSMultisigFactory();
        multisig = factory.createBasicMultisig(members, 2, 24 hours);
        foo(123);
    }

    function test_setup() {
        assertEq(multisig.members(), 3);
        assertEq(multisig.member(0), this);
        assertEq(multisig.member(1), alice);
        assertEq(multisig.member(2), bob);
        assertTrue(multisig.isMember(this));
        assertTrue(multisig.isMember(alice));
        assertTrue(multisig.isMember(bob));
        assertFalse(multisig.isMember(eve));
        assertEq(uint(multisig.quorum()), 2);
        assertEq(uint(multisig.window()), 24 hours);
        assertEq(multisig.actions(), 0);
    }

    function test_propose() {
        assertEq(multisig.propose(dummy), 0);
        assertEq(multisig.actions(), 1);
        assertEq(multisig.target(0), dummy);
        assertEq(multisig.callsize(0), 0);
        assertEq(multisig.value(0), 0);
        assertEq(uint(multisig.expiration(0)), now + 24 hours);
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
        assertEq(multisig.actions(), 2);
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
        dummy.fail();
        multisig.trigger(0);
        assertTrue(multisig.triggered(0));
        assertFalse(multisig.succeeded(0));
        assertFalse(dummy.fallbackCalled());
    }

    function test_payment() {
        assertTrue(multisig.call.value(500)());
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
