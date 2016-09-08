import "basic_multisig.sol";

contract DSMultisigFactory {
    function createBasicMultisig(
        address[] members, uint8 quorum, uint40 window
    ) returns (DSBasicMultisig) {
        return new DSBasicMultisig(members, quorum, window);
    }
}
