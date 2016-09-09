import 'auth/auth.sol';
import 'easy_multisig.sol';

contract DSEasyMultisigFactory is DSAuthUser {
    mapping(address=>bool) is_easy_multisig;

    function buildDSEasyMultisig( uint n, uint m, uint expiration ) returns (DSEasyMultisig ret)
    {
        ret = new DSEasyMultisig( n, m, expiration );
        is_easy_multisig[address(ret)] = true;
        setOwner( ret, msg.sender );
    }

    // members.length <= m must be true because DSEasyMultisig Owner
    // is set to null when the last member of m is added
    function buildDSEasyMultisigWithMembers( uint n, uint m, uint expiration, address[] members ) returns (DSEasyMultisig ret)
    {
        ret = new DSEasyMultisig( n, m, expiration );
        is_easy_multisig[address(ret)] = true;

        for (var i = 0; i < members.length; i++) {
            ret.addMember(members[i]);
        }

        if (members.length < m) {
            setOwner( ret, msg.sender );
        }
    }

    function isDSEasyMultisig(address code)
        constant
        returns (bool)
    {
        return is_easy_multisig[code];
    }
}
