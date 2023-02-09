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

```
export AUTH_SUBNET_MINER_ADDR=ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP
export AUTH_SUBNET_MINER_KEY=6a1a754ba863d7bab14adbbc3f8ebb090af9e871ace621d3e5ab634e1422885e01

export USER_ADDR=ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
export USER_KEY=f9d7206a47f14d2870c163ebab4bf3e70d18f5d14ce1031f3902fbbc894fe4c701

export ALT_USER_ADDR=ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
export ALT_USER_KEY=3eccc5dac8056590432db6a35d52b9896876a3d5cbdea53b72400bc9c2099fe801
export SUBNET_URL="http://localhost:30443"
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

```
node ./publish_tx.js simple-nft-l1 ../contracts/simple-nft.clar 1 0
```

Verify that the contract was published by using the Clarinet console. For the
layer 1 contracts, you should see the following in the "transactions" region in
a recent block.

🟩 deployed: ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1 (ok true)

Then, publish the layer 2 contracts. Note, it might take a minute for the subnet
node to start accepting transactions, so these commands could fail if you send
them too early (but you can always re-try when the node is ready). These
transactions are called by the principal `USER_ADDR`.

```
node ./publish_tx.js simple-nft-l2 ../contracts-l2/simple-nft-l2.clar 2 0
```

To verify that the layer 2 transactions were processed, grep the subnet log for
the transaction IDs of _each_ subnet transaction. The transaction ID is logged
to the console after the call to `publish_tx` - make sure this is the ID you
grep for.

```
grep 219bae673fb5037e657dfae5981288c22cf156497b0e6ecbc683058fe5efb49f ../subnet.log
```

Look for a log line similar to the following in the results:

```
INFO [1675951620.159943] [src/chainstate/stacks/miner.rs:287] [relayer] Tx successfully processed., event_name: transaction_result, tx_id: 219bae673fb5037e657dfae5981288c22cf156497b0e6ecbc683058fe5efb49f, event_type: success, payload: SmartContract
```

To ensure the contracts were successfully parsed and published, we will grep for
the name of the contract and ensure there are no error lines returned (not
atypical for no lines to be returned at this step).

```
grep "simple-nft-l2" ../subnet.log
```

## Step 2: Register the new NFT asset in the interface subnet contract

Create the transaction to register the new NFT asset we just published. This
must be called by a miner of the subnet contract. Specifically, this transaction
will be sent by `AUTH_SUBNET_MINER_ADDR`.

```
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

```
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

```
node ./deposit_nft.js 2
```

Verify that the transaction is acknowledged in the next few blocks of the L1
chain. After the transaction is confirmed in an anchored block on the L1 (this
means it is included in an explicitly numbered block in the Clarinet console),
you also may want to verify that the asset was successfully deposited on the
subnet by grepping for the deposit transaction ID.

```
grep 0e5428fac10982e6a96cf87e73951bfa794d592d78e9b565568182017bbca0b3 ../subnet.log
```

Look for a line like:

```
@@@ Processing deposit FT ops: [DepositNftOp { txid: 0e5428fac10982e6a96cf87e73951bfa794d592d78e9b565568182017bbca0b3, burn_header_hash: 607c42d8c184543df6eb31e47cc8371e55af57337e221a11b1a2feb885ed556a, l1_contract_id: QualifiedContractIdentifier { issuer: StandardPrincipalData(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND), name: ContractName("simple-nft-l1") }, subnet_contract_id: QualifiedContractIdentifier { issuer: StandardPrincipalData(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND), name: ContractName("simple-nft-l2") }, id: 5, sender: Standard(StandardPrincipalData(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)) }] ST000000000000000000002AMW42H
```

## Step 5: Transfer the NFT within the Subnet

On the subnet, the NFT should belong to the principal that sent the deposit
transaction, `USER_ADDR`. This principal can now transfer the NFT within the
subnet. The principal `USER_ADDR` will now make a transaction to transfer the
NFT to `ALT_USER_ADDR`.

```
node ./transfer_nft.js 1
```

Grep for the transaction ID of the transfer transaction.

```
grep 6acc2c756ddaed2c4cfb7351dd5930aa93ba923504be85e47db056c99a7e81aa ../subnet.log
```

Look for something like the following line:

```
INFO [1675953134.677706] [src/chainstate/stacks/miner.rs:287] [relayer] Tx successfully processed., event_name: transaction_result, tx_id: 6acc2c756ddaed2c4cfb7351dd5930aa93ba923504be85e47db056c99a7e81aa, event_type: success, payload: ContractCall
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

```
node ./withdraw_nft_l2.js 0
```

Grep the subnet node to ensure success:

```
docker logs subnet-node.nft-use-case.devnet 2>&1 | grep "5b5407ab074b4d78539133fe72020b18d44535a586574d0bd1f668e05dc89c2f"
Jul 19 13:07:33.804109 INFO Tx successfully processed. (ThreadId(9), src/chainstate/stacks/miner.rs:235), event_name: transaction_result, tx_id: 3ff9b9b0f33dbd6087f302fa9a7a113466cf7700ba7785a741b391f5ec7c5ba4, event_type: success, payload: ContractCall

docker logs subnet-node.nft-use-case.devnet 2>&1 | grep "withdraw-nft-asset"
Jul 19 13:22:34.800652 INFO Contract-call successfully processed (ThreadId(8), src/chainstate/stacks/db/transactions.rs:731), contract_name: ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG.simple-nft-l2, function_name: withdraw-nft-asset, function_args: [u5, ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC], return_value: (ok true), cost: ExecutionCost { write_length: 2, write_count: 2, read_length: 1647, read_count: 5, runtime: 2002000 }
```

In order to successfully complete the withdrawal on the L1, it is necessary to
know the height at which the withdrawal occurred. You can find the height of the
withdrawal using grep:

```
docker logs subnet-node.nft-use-case.devnet 2>&1 | grep "Parsed L2 withdrawal event"
Jul 19 13:22:34.801290 INFO Parsed L2 withdrawal event (ThreadId(8), src/clarity_vm/withdrawal.rs:56), type: nft, block_height: 47, sender: ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC, withdrawal_id: 0, asset_id: ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG.simple-nft-l2::nft-token
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

```
node ./withdraw_nft_l1.js {WITHDRAWAL_BLOCK_HEIGHT} 1
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
