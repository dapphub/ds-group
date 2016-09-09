import 'auth/auth.sol';
import 'easy_multisig.sol';

contract DSEasyMultisigFactory is DSAuthUser {
    mapping(address=>bool) public isDSEasyMultisig;

    function buildDSEasyMultisig( uint n, uint m, uint expiration ) returns (DSEasyMultisig ret)
    {
        ret = new DSEasyMultisig( n, m, expiration );
        isDSEasyMultisig[address(ret)] = true;
        setOwner( ret, msg.sender );
    }

    // members.length <= m must be true because DSEasyMultisig Owner
    // is set to null when the last member of m is added
    function buildDSEasyMultisigWithMembers( uint n, uint m, uint expiration, address[] members ) returns (DSEasyMultisig ret)
    {
        ret = new DSEasyMultisig( n, m, expiration );
        isDSEasyMultisig[address(ret)] = true;

        for (var i = 0; i < members.length; i++) {
            ret.addMember(members[i]);
        }

        if (members.length < m) {
            setOwner( ret, msg.sender );
        }
    }
}
