Overview
========

This package contains an m-of-n multisig contract as well as a
command-line interface for working with such multisig instances.

Please join <https://dapphub.chat/> for more information.


Multisig contract deployment
============================

The `DSGroup` contract takes three parameters:

```
    function DSGroup(
        address[]  members_,
        uint       quorum_,
        uint       window_
    ) { … }
```

- `address[] members_` is the list of group members. They will be able
  to create new proposals, accept them and trigger their execution.
- `uint quorum_` is the minimum number of members who have to accept
  a proposal before it can be triggered.
- `uint window_` is the proposal validity time in seconds.

Use Dapp (<https://github.com/dapphub/dapp>) to build and deploy
the contract:

```bash
dapp build
dapp deploy DSGroup '[0011111111111111111111111111111111111111,0022222222222222222222222222222222222222,0033333333333333333333333333333333333333]' 2 86400
```


Command-line interface
======================

The `ds-group(1)` program is a convenient way to work with groups.

To install the command-line program, type `make link`.  You need to
have Seth installed to use it (<https://github.com/dapphub/seth>).


Synopsis
--------

    Usage: ds-group <command> <group> [<args>]
       or: ds-group <command> --help

    Propose, confirm and trigger DSGroup multisig actions.

    Commands:

       action        print information about a multisig action
       confirm       confirm a proposed multisig action
       ls            list already-proposed multisig actions
       propose       propose a new multisig action
       trigger       trigger a confirmed multisig action
       verify        verify the meaning of a multisig action


Examples
--------

    ~$ ds-group ls @mkrgroup
        ACT  CONFIRMATIONS      EXPIRATION  STATUS
         15   0/6 (need 4)        8 h left  Unconfirmed
         16   0/6 (need 4)        9 h left  Unconfirmed

    ~$ ds-group propose @mkrgroup @feedbase 0 "claim()"
    Proposing action...
      target     0x5927c5cc723c4486f93bf90bad3be8831139499e
      value      0
      calldata   0x4e71d92d
    seth-send: 0x307b667c434794c234b7c463b26827bdceb9c838fdb306f3f4398edefa5b1310
    seth-send: Waiting for transaction receipt.........................
    seth-send: Transaction included in block 1519991.
    seth-send: note: return value may be inaccurate (see `seth send --help')
    Successfully proposed act 17.

    ~$ ds-group ls @mkrgroup
        ACT  CONFIRMATIONS      EXPIRATION  STATUS
         15   0/6 (need 4)        8 h left  Unconfirmed
         16   0/6 (need 4)        9 h left  Unconfirmed
         17   0/6 (need 4)       23 h left  Unconfirmed

    ~$ ds-group confirm @mkrgroup 17
    Confirming action 17...
    seth-send: 0x72fc6bf7c5135645a0fa298aa3ae01e072a82eabfddc8e3fbcdca72d0007d94b
    seth-send: Waiting for transaction receipt...............
    seth-send: Transaction included in block 1520018.

    ~$ ds-group ls @mkrgroup
     ACTION  CONFIRMATIONS      EXPIRATION  STATUS
         15   0/6 (need 4)        8 h left  Unconfirmed
         16   0/6 (need 4)        9 h left  Unconfirmed
         17   1/6 (need 4)       23 h left  Unconfirmed

    ~$ ds-group trigger @mkrgroup 17
    ds-group-trigger: error: act not confirmed: 17

    ~$ ds-group action @mkrgroup 17
    calldata        0x4e71d92d
    confirmations   1
    confirmed       false
    deadline        1471876934
    expired         false
    status          Unconfirmed
    target          0x5927c5cc723c4486f93bf90bad3be8831139499e
    triggered       false
    value           0
