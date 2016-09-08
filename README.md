ds-multisig
===========

This repository contains two multisig implementations and one factory.

`DSEasyMultisig` is what used to be `dappsys/gov/easy_multisig`.

`DSBasicMultisig` is a new implementation.  It has the following API:

    createBasicMultisig (address[] members, uint8 quorum, uint40 window)

    quorum  () returns (uint8)
    window  () returns (uint40)

    members () returns (uint count)
    member        (uint id) returns (address)
    isMember      (address) returns (bool)

    actions () returns (uint count)
    target        (uint id) returns (address)
    calldata      (uint id) returns (bytes)
    callsize      (uint id) returns (uint)
    callhash      (uint id) returns (bytes32)
    value         (uint id) returns (uint)
    expiration    (uint id) returns (uint40)
    expired       (uint id) returns (bool)

    propose (address target, bytes calldata, uint value) returns (uint id)
    propose (address target, bytes calldata)             returns (uint id)
    propose (address target, uint value)                 returns (uint id)
    propose (address target)                             returns (uint id)

    confirm       (uint id)
    confirmations (uint id) returns (uint8 count)
    confirmed     (uint id) returns (bool)
    confirmedBy   (uint id, address) returns (bool)

    trigger       (uint id)
    triggered     (uint id) returns (bool)
    succeeded     (uint id) returns (bool)
