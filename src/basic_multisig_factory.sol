import "basic_multisig.sol";

contract DSMultisigFactory {
    mapping (address => bool) public isBasicMultisig;

    function createBasicMultisig(
        address[] members, uint8 quorum, uint40 window
    ) returns (DSBasicMultisig result) {
        result = new DSBasicMultisig(members, quorum, window);
        isBasicMultisig[result] = true;
    }
}
