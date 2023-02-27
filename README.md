## Setup

- Checkout the `mint-with-trait` branch of the
  [stacks-subnets repo](https://github.com/hirosystems/stacks-subnets), then
  build the subnet-node.

  ```sh
  git clone https://github.com/hirosystems/stacks-subnets.git
  cd stacks-subnets
  git checkout mint-with-trait
  cd testnet/stacks-node
  cargo build --features monitoring_prom,slog_json --release
  ```

- Launch the subnet node

  ```sh
  subnet-node start --config ./Subnet.toml 2>&1 | tee subnet.log
  ```

  (this needs to happen first, or else the stacks-node will stall, waiting for
  the observer)

  - Note that if you run this multiple times, clear out the ./devnet/ directory
    before re-starting the subnet node (`rm -rf ./devnet/*`)

- Clone this repository and launch a devnet:

  ```sh
  git clone https://github.com/obycode/nft-use-case.git
  cd nft-use-case
  clarinet integrate
  ```

- Verify that at block 5, the subnet contract is successfully deployed. After
  that, you should see successful calls to `commit-block` in each Stacks block.

Before we publish any transactions, you will need to set up some environment
variables. These environment variables contain the address and private key of
the subnet miner, two user addresses and private keys, and the RPC URL which we
can query for subnet state. Open a separate terminal window, navigate to the
directory `nft-use-case/scripts`, and enter the following.

```sh
export AUTH_SUBNET_MINER_ADDR=ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP
export AUTH_SUBNET_MINER_KEY=6a1a754ba863d7bab14adbbc3f8ebb090af9e871ace621d3e5ab634e1422885e01

export USER_ADDR=ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
export USER_KEY=f9d7206a47f14d2870c163ebab4bf3e70d18f5d14ce1031f3902fbbc894fe4c701

export ALT_USER_ADDR=ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
export ALT_USER_KEY=3eccc5dac8056590432db6a35d52b9896876a3d5cbdea53b72400bc9c2099fe801
export SUBNET_URL="http://localhost:30443"
```

While in the `scripts` directory, we will also need to install some NPM dependencies
which are used by our scripts:

```sh
npm install
```

## Step 1: Publish the NFT contract to the Stacks L1 and the Subnet

Once the Stacks node and the subnet node boots up (use the indicators in the top
right panel to determine this), we can start to interact with the chains. To
begin with, we want to publish NFT contracts onto both the L1 and L2. When the
user deposits their L1 NFT onto the subnet, their asset gets minted by the L2
NFT contract. The publish script takes in four arguments: the name of the
contract to be published, the filename for the contract source code, the layer
on which to broadcast the transaction (1 or 2), and the nonce of the
transaction. First, publish the layer 1 contracts. You can enter this command
(and the following transaction commands) in the same terminal window as you
entered the environment variables. Make sure you are in the `scripts` directory.
These transactions are called by the principal `USER_ADDR`.

```sh
node ./publish_tx.js simple-nft-l1 ../contracts/simple-nft.clar 1 0
```

Verify that the contract was published by using the Clarinet console. For the
layer 1 contracts, you should see the following in the "transactions" region in
a recent block.

🟩 deployed: ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1 (ok true)

Then, publish the layer 2 contracts. Note, it might take a minute for the subnet
node to start accepting transactions, so these commands could fail if you send
them too early (but you can always re-try when the node is ready). It should
work if the transaction is sent after the first `block-commit` is in an anchor
block. These transactions are called by the principal `USER_ADDR`.

```sh
node ./publish_tx.js simple-nft-l2 ../contracts-l2/simple-nft-l2.clar 2 0
```

To verify that the layer 2 transactions were processed, grep the subnet log for
the transaction IDs of _each_ subnet transaction. The transaction ID is logged
to the console after the call to `publish_tx` - make sure this is the ID you
grep for.

```sh
grep 219bae673fb5037e657dfae5981288c22cf156497b0e6ecbc683058fe5efb49f ../subnet.log
```

Look for a log line similar to the following in the results:

```
INFO [1675951620.159943] [src/chainstate/stacks/miner.rs:287] [relayer] Tx successfully processed., event_name: transaction_result, tx_id: 219bae673fb5037e657dfae5981288c22cf156497b0e6ecbc683058fe5efb49f, event_type: success, payload: SmartContract
```

To ensure the contracts were successfully parsed and published, we will grep for
the name of the contract and ensure there are no error lines returned (not
atypical for no lines to be returned at this step).

```sh
grep "simple-nft-l2" ../subnet.log
```

## Step 2: Register the new NFT asset in the interface subnet contract

Create the transaction to register the new NFT asset we just published. This
must be called by a miner of the subnet contract. Specifically, this transaction
will be sent by `AUTH_SUBNET_MINER_ADDR`.

```sh
node ./register_nft.js
```

Look for the following transaction confirmation in the Clarinet console in an
upcoming block on the layer 1.

🟩 invoked:
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.subnet::register-new-nft-contract(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1,
ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l2) (ok true)

## Step 3: Mint an NFT on the L1 Chain

Let's create a transaction to mint an NFT on the L1 chain. Once this transaction
is processed, the principal `USER_ADDR` will own an NFT.

```sh
node ./mint_nft.js 1
```

Verify that the transaction is acknowledged within the next few blocks in the
Stacks explorer.

🟩 invoked:
ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1::gift-nft(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND,
u5) (ok true)

## Step 4: Deposit the NFT onto the Subnet

Now, we can call the deposit NFT function in the subnet interface contract. This
function is called by the principal `USER_ADDR`.

```sh
node ./deposit_nft.js 2
```

Verify that the transaction is acknowledged in the next few blocks of the L1
chain. After the transaction is confirmed in an anchored block on the L1 (this
means it is included in an explicitly numbered block in the Clarinet console),
you also may want to verify that the asset was successfully deposited on the
subnet by grepping for the deposit operation.

```sh
grep DepositNftOp ../subnet.log
```

Look for a line like:

```
@@@ Processing deposit FT ops: [DepositNftOp { txid: 62742f91aaa54428998cc191b53829f8e89c4d211a187e513ce8d40010002b8a, burn_header_hash: b0f6d6cd1e031d2a684992cd122ff91df333de1439110dd5b6b89b8138b04e53, l1_contract_id: QualifiedContractIdentifier { issuer: StandardPrincipalData(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND), name: ContractName("simple-nft-l1") }, subnet_contract_id: QualifiedContractIdentifier { issuer: StandardPrincipalData(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND), name: ContractName("simple-nft-l2") }, id: 5, sender: Standard(StandardPrincipalData(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)) }] ST000000000000000000002AMW42H
```

## Step 5: Transfer the NFT within the Subnet

On the subnet, the NFT should belong to the principal that sent the deposit
transaction, `USER_ADDR`. This principal can now transfer the NFT within the
subnet. The principal `USER_ADDR` will now make a transaction to transfer the
NFT to `ALT_USER_ADDR`.

```sh
node ./transfer_nft.js 1
```

Grep for the transfer transaction.

```sh
grep transfer ../subnet.log
```

Look for something like the following line:

```
INFO [1675972087.659820] [src/chainstate/stacks/db/transactions.rs:747]
[relayer] Contract-call successfully processed, contract_name:
ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l2, function_name: transfer,
function_args: [u5, ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND,
ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB], return_value: (ok true), cost:
ExecutionCost { write_length: 1, write_count: 1, read_length: 1999, read_count:
4, runtime: 2807000 }
```

For a bonus step, you can try minting an NFT on the subnet. This would require
calling the `gift-nft` function in the contract `simple-nft-l2`. You can tweak
the `transfer_nft.js` file to make this call.

## Step 6: Withdraw the NFT back to the L1 Chain

### Background on withdrawals

Withdrawals from the subnet are a 2-step process.

The owner of an asset must call `withdraw-ft?` / `withdraw-stx?` /
`withdraw-nft?` in a Clarity contract on the subnet, which destroys those assets
on the subnet, and adds that particular withdrawal to a withdrawal data
structure for that block. The withdrawal data structure serves as a
cryptographic record of the withdrawals in a particular block, and has an
overall associated hash. This hash is committed to the L1 interface contract via
the `commit-block` function.

The second step involves calling the appropriate withdraw function in the subnet
interface contract on the L1 chain. You must also pass in the "proof" that
corresponds to your withdrawal. This proof includes the hash of the withdrawal
data structure that this withdrawal was included in, the hash of the withdrawal
itself, and a list of hashes to be used to prove that the particular withdrawal
is valid. Currently, this function must be called by a subnet miner, but in an
upcoming subnet release, the asset owner must call this function.

### Step 6a: Withdraw the NFT on the subnet

Perform the withdrawal on the layer 2 by calling `withdraw-nft-asset` in the
`simple-nft-l2` contract. This will be called by the principal `ALT_USER_ADDR`.

```sh
node ./withdraw_nft_l2.js 0
```

Grep the subnet node to ensure success:

```sh
grep "nft-withdraw?" ../subnet.log
```

Look for something like the following:

```
INFO [1675960297.875772] [src/chainstate/stacks/db/transactions.rs:747]
[relayer] Contract-call successfully processed, contract_name:
ST000000000000000000002AMW42H.subnet, function_name: nft-withdraw?,
function_args: [ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l2, u5,
ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB], return_value: (ok true), cost:
ExecutionCost { write_length: 2, write_count: 2, read_length: 4738, read_count:
8, runtime: 6439000 } INFO [1675960358.091130]
[src/chainstate/stacks/db/transactions.rs:747] [chains-coordinator]
Contract-call successfully processed, contract_name:
ST000000000000000000002AMW42H.subnet, function_name: nft-withdraw?,
function_args: [ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l2, u5,
ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB], return_value: (ok true), cost:
ExecutionCost { write_length: 2, write_count: 2, read_length: 4738, read_count:
8, runtime: 6439000 }
```

In order to successfully complete the withdrawal on the L1, it is necessary to
know the height at which the withdrawal occurred. You can find the height of the
withdrawal using grep:

```sh
grep "Parsed L2 withdrawal event" ../subnet.log
```

Look for something like the following:

```
INFO [1675960297.877492] [src/clarity_vm/withdrawal.rs:157] [relayer] Parsed L2
withdrawal event, type: nft, block_height: 102, sender:
ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB, withdrawal_id: 0, asset_id:
ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l2
```

Get the withdrawal height by looking at the `block_height` in the returned line.
There may be multiple lines returned by the grep. Try the higher heights first,
and work backward.

### Step 6b: Complete the withdrawal on the Stacks chain

Use the withdrawal height we just obtained from the grep and substitute that for
`WITHDRAWAL_BLOCK_HEIGHT`. You might need to wait a little bit for the subnet
block to become official (even if the grep already returned a result) for the
transaction to succeed. If the subnet has not advanced sufficiently, you may get
the error `Supplied block height not found`. For now, this script assumes that
the requested withdrawal was the only one in the subnet block it was a part of
(thus, you may run into issues using this script if you are attempting to
withdraw multiple assets in a short span of time).

```sh
node ./withdraw_nft_l1.js {WITHDRAWAL_BLOCK_HEIGHT} 0
```

Check for the success of this transaction in the Clarinet console:

🟩 invoked:
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.subnet::withdraw-nft-asset(u5,
ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05...

You can also navigate to the Stacks Explorer (the URL of this will be listed in
the Clarinet console), and check that the expected principal now owns the NFT
(`ALT_USER_ADDR`). You can check this by clicking on the transaction
corresponding to `withdraw-nft-asset`.

That is the conclusion of this demo! If you have any issues with this demo,
reach out on the Stacks Discord or leave an issue in the stacks-subnets
repository.

Verify that the correct address now owns the NFT by calling:

```sh
node ./verify.js
```

The result is printed to the terminal, and should show:

```
(some ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)
```
