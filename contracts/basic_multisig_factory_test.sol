import 'dapple/test.sol';
import "basic_multisig_factory.sol";

contract DSMultisigFactoryTest is Test {
    DSMultisigFactory factory;

    function setUp() {
        factory = new DSMultisigFactory();
    }

    function testIsBasicMultisig() {
        address[] memory m = new address[](1);
        m[0] = this;
        DSBasicMultisig ms = factory.createBasicMultisig(m, 1, 24 hours);
        assertTrue(factory.isBasicMultisig(address(ms)), "Not a multisig");
        assertFalse(factory.isBasicMultisig(address(0x0)), "Not supposed to be a multisig");

    }

    function testCreateCostBasicMultisig() logs_gas() {
        factory = new DSMultisigFactory();
    }

}
