<h2>DSGroup</h2>

_Multisig with a command-line interface_

The ds-group library is `DSGroup` with a command-line interface. A list of 
`members`, the required `quorum` and the `window` of time in which actions
must be approved are fixed when the `DSGroup` contract is created. Actions can 
then be proposed, confirmed and triggered once a group quorum has been reached.

## Installation & deployment

The `DSGroup` contract takes three parameters:

```
function DSGroup(address[] members, uint quorum, uint window)
```

#### `address[] members` 
The list of group members. They will be able to create new proposals, accept them and trigger their execution.

#### `uint quorum` 
The minimum number of members who have to accept a proposal before it can be triggered.

#### `uint window` 
The proposal validity time in seconds.

Install [Dapp](https://dapp.tools/dapp/) to build and deploy the contract:

```bash
dapp build
dapp create DSGroup '[
  0011111111111111111111111111111111111111,
  0022222222222222222222222222222222222222,
  0033333333333333333333333333333333333333
]' 2 86400
```

Install the [Seth](https://dapp.tools/seth/) dependency in order to use the 
command line interface. Then type `make link` from the ds-group directory 
to install the `ds-group` CLI tool:

```bash
Usage: ds-group <command> <group> [<args>]
   or: ds-group <command> --help

Commands:

action        print information about a multisig action
confirm       confirm a proposed multisig action
ls            list already-proposed multisig actions
propose       propose a new multisig action
trigger       trigger a confirmed multisig action
verify        verify the meaning of a multisig action
```

### Examples

```bash
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
```
