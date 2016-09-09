import "basic_multisig.sol";

contract DSMultisigFactory {
    mapping(address=>bool) is_basic_multisig;

    function createBasicMultisig(
        address[] members, uint8 quorum, uint40 window
    ) returns (DSBasicMultisig ret) {
        ret = new DSBasicMultisig(members, quorum, window);
        is_basic_multisig[address(ret)] = true;
    }

    function isBasicMultisig(address code)
        constant
        returns (bool)
    {
        return is_basic_multisig[code];
    }

}
