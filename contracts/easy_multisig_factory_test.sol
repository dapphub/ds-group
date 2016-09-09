import 'dapple/test.sol';
import 'easy_multisig_factory.sol';

contract DSEasyMultisigFactoryTest is Test {
    DSEasyMultisigFactory factory;

    address t1 = address(0x1);
    address t2 = address(0x2);
    address t3 = address(0x3);
    address[] members;

    function setUp() {
        factory = new DSEasyMultisigFactory();
    }

    function testBuildDSEasyMultisig() {
        DSEasyMultisig ms = factory.buildDSEasyMultisig(2, 3, 3 days);
        assertDefaultEasyMultisigConfig(ms);
    }

    function testBuildDSEasyMultisigWithAllMembers() {
        members.push(t1);
        members.push(t2);
        members.push(t3);

        DSEasyMultisig ms = factory.buildDSEasyMultisigWithMembers(2, 3, 3 days, members);
        assertDefaultEasyMultisigConfigWithMembers(ms);
    }

    function testBuildDSEasyMultisigWithFewerMembers() {
        members.push(t1);
        members.push(t2);

        DSEasyMultisig ms = factory.buildDSEasyMultisigWithMembers(2, 3, 3 days, members);

        ms.addMember(t3);
        assertDefaultEasyMultisigConfigWithMembers(ms);
    }

    function testFailBuildDSEasyMultisigWithTooManyMembers() {
        members.push(t1);
        members.push(t2);
        members.push(t3);
        members.push(address(this));
        DSEasyMultisig ms = factory.buildDSEasyMultisigWithMembers(2, 3, 3 days, members);
    }

    function testIsDSEasyMultisig() {
        DSEasyMultisig ms = factory.buildDSEasyMultisig(2, 3, 3 days);
        assertTrue(factory.isDSEasyMultisig(address(ms)), "Not a multisig");
        assertFalse(factory.isDSEasyMultisig(address(0x0)), "Not supposed to be a multisig");
    }

    function testCreateCostDSEasyMultisig() logs_gas() {
        factory = new DSEasyMultisigFactory();
    }

    function assertDefaultEasyMultisigConfig(DSEasyMultisig ms) {
        var (r, m, e, n) = ms.getInfo();
        assertTrue(r == 2, "wrong required signatures");
        assertTrue(m == 3, "wrong member count");
        assertTrue(e == 3 days, "wrong expiration");
        assertTrue(n == 0, "wrong last action");
    }

    function assertDefaultEasyMultisigConfigWithMembers(DSEasyMultisig ms) {
        assertDefaultEasyMultisigConfig(ms);
        assertTrue(ms.isMember(t1), "Expected 0x1 to be a member");
        assertTrue(ms.isMember(t2), "Expected 0x2 to be a member");
        assertTrue(ms.isMember(t3), "Expected 0x3 to be a member");
    }

}
