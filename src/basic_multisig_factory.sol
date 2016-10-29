import "basic_multisig.sol";

contract DSMultisigFactory {
    mapping(address=>bool) public isBasicMultisig;

    function createBasicMultisig(
        address[] members, uint8 quorum, uint40 window
    ) returns (DSBasicMultisig ret) {
        ret = new DSBasicMultisig(members, quorum, window);
        isBasicMultisig[address(ret)] = true;
    }

}
