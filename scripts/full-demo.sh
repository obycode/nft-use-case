#!/bin/bash

# function used to extract the txid from the node scripts' outputs
extract_txid() {
  output="$1"
  txid=$(echo $output | grep -o -E "'[0-9a-fA-F]+'")
  if [ -z "$txid" ]; then
    echo "Error: txid not found in the output."
    echo "$output"
    return 1
  fi
  txid=${txid#\'}
  txid=${txid%\'}
  echo $txid
}

echo "Start the subnet node first, teeing the output to a file:"
echo "  $ STACKS_DEBUG=1 subnet-node start --config ./Subnet.toml 2>&1 | tee subnet.log"
read
rm -rf ../devnet/*
osascript -e 'tell application "iTerm2"
  set newWindow to (create window with default profile)
  tell current session of newWindow
    write text "cd ~/work/nft-use-case-custom"
    write text "STACKS_DEBUG=1 ~/work/stacks-subnets/target/release/subnet-node start --config ./Subnet.toml 2>&1 | tee subnet.log"
  end tell
end tell'
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │    subnet    │
                            │              │
                            │              │
                            │              │
                            └──────────────┘
"

read
echo "################################################################################"
echo "Start the bitcoin node and stacks nodes, using 'clarinet integrate' in another terminal"
echo "  $ clarinet integrate"
read
osascript -e 'tell application "iTerm2"
  set newWindow to (create window with default profile)
  tell current session of newWindow
    write text "cd ~/work/nft-use-case-custom"
    write text "clarinet integrate"
  end tell
end tell'
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    stacks    │
                            │              │
                            │     ┌────────┤
                            │     │ subnet │
                            └───┬─┴────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    subnet    │
                            │              │
                            │              │
                            │              │
                            └──────────────┘
"
echo "Watch this window, waiting for the 2.1 epoch to go live and the subnet
  contract to be published. This should happen around block 5 or 6.

  🟩 deployed: ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.subnet (ok true)
"

read
echo "################################################################################"
echo "Setup some environment variables to be used when sending transactions:"
echo '
export AUTH_SUBNET_MINER_ADDR=ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP
export AUTH_SUBNET_MINER_KEY=6a1a754ba863d7bab14adbbc3f8ebb090af9e871ace621d3e5ab634e1422885e01

export USER_ADDR=ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
export USER_KEY=f9d7206a47f14d2870c163ebab4bf3e70d18f5d14ce1031f3902fbbc894fe4c701

export ALT_USER_ADDR=ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
export ALT_USER_KEY=3eccc5dac8056590432db6a35d52b9896876a3d5cbdea53b72400bc9c2099fe801
export SUBNET_URL="http://localhost:30443"
'
read
export AUTH_SUBNET_MINER_ADDR=ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP
export AUTH_SUBNET_MINER_KEY=6a1a754ba863d7bab14adbbc3f8ebb090af9e871ace621d3e5ab634e1422885e01

export USER_ADDR=ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
export USER_KEY=f9d7206a47f14d2870c163ebab4bf3e70d18f5d14ce1031f3902fbbc894fe4c701

export ALT_USER_ADDR=ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
export ALT_USER_KEY=3eccc5dac8056590432db6a35d52b9896876a3d5cbdea53b72400bc9c2099fe801
export SUBNET_URL="http://localhost:30443"

echo "################################################################################"
echo "Publish the NFT contract to the L1 Stacks network"
echo "  $ node ./publish_tx.js simple-nft-l1 ../contracts/simple-nft.clar 1 0"
read
node ./publish_tx.js simple-nft-l1 ../contracts/simple-nft.clar 1 0
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
        ┌────────┐          │              │
        │ nft-l1 ├──────────►              │
        │  .clar │          │    stacks    │
        └────────┘          │              │
                            │     ┌────────┤
                            │     │ subnet │
                            └───┬─┴────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    subnet    │
                            │              │
                            │              │
                            │              │
                            └──────────────┘
"
echo "We'll know this is successful when we see the successful deployment in the
  set of transactions in the 'clarinet integrate' window (as below).

  🟩 deployed: ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1 (ok true)"

read
echo "################################################################################"
echo "Publish the NFT contract to the L2 Subnet network"
echo "  $ node ./publish_tx.js simple-nft-l2 ../contracts-l2/simple-nft-l2.clar 2 0"
read
result=$(node ./publish_tx.js simple-nft-l2 ../contracts-l2/simple-nft-l2.clar 2 0)
if [ $? -ne 0 ]; then
  exit 1
fi
txid=$(extract_txid "$output")
if [ $? -ne 0 ]; then
  echo $txid
  exit 1
fi
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    stacks    │
                            │              │
                            │     ┌────────┤
                            │     │ subnet │
                            └───┬─┴────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
        ┌────────┐          │              │
        │ nft-l2 ├──────────►              │
        │  .clar │          │    subnet    │
        └────────┘          │              │
                            │              │
                            │              │
                            └──────────────┘
"
echo "We won't see the L2 transactions in the 'clarinet integrate' window, but we
  can check the subnet's logs to see that the contract was successfully deployed.
  The above command prints the txid of the transaction that deployed the contract.
  We can grep for that in the logs:

  $ grep $txid ../subnet.log
  INFO [1676063868.274023] [src/chainstate/stacks/miner.rs:287] [relayer] Tx successfully processed., event_name: transaction_result, tx_id: 219bae673fb5037e657dfae5981288c22cf156497b0e6ecbc683058fe5efb49f, event_type: success, payload: SmartContract
"
grep $txid ../subnet.log
read
echo "To ensure the contracts were successfully parsed and published, we will grep for
the name of the contract and ensure there are no error lines returned (not
atypical for no lines to be returned at this step).

grep \"simple-nft-l2\" ../subnet.log
"
grep "simple-nft-l2" ../subnet.log

read
echo "################################################################################"
echo "Register this NFT with the Subnet"
echo "  $ node ./register_nft.js"
read
node ./register_nft.js
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    stacks    │
                            │              │
        ┌──────────┐        │     ┌────────┤
        │ register ├────────┼─────► subnet │
        └──────────┘        └───┬─┴────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    subnet    │
                            │              │
                            │              │
                            │              │
                            └──────────────┘
"
echo "Look for the transaction confirmation in the Clarinet console in an
  upcoming block on the layer 1.

  🟩 invoked: ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.subnet::register-new-nft-contract(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1, ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l2) (ok true)
"

read
echo "################################################################################"
echo "Mint an NFT on the L1 Stacks network"
echo "  $ node ./mint_nft.js 1"
read
node ./mint_nft.js 1
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │ ┌─A──┐
              ┌──────┐      │              │ │ u5 │
              │ mint ├──────►    stacks    │ └────┘
              └──────┘      │              │
                            │     ┌────────┤
                            │     │ subnet │
                            └───┬─┴────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    subnet    │
                            │              │
                            │              │
                            │              │
                            └──────────────┘
"
echo "Look for the transaction confirmation in the Clarinet console in an
  upcoming block on the layer 1.

  🟩 invoked: ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1::gift-nft(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND, u5) (ok true)
"

read
echo "################################################################################"
echo "Deposit the NFT into the L2 Subnet network"
echo "  $ node ./deposit_nft.js 2"
read
result=$(node ./deposit_nft.js 2)
if [ $? -ne 0 ]; then
  exit 1
fi
txid=$(extract_txid "$output")
if [ $? -ne 0 ]; then
  echo $txid
  exit 1
fi
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    stacks    │
                            │              │
            ┌─────────┐     │     ┌────────┤ ┌────┐
            │ deposit ├─────┼─────► subnet │ │ u̶5̶ │
            └─────────┘     └───┬─┴────▲───┘ └─┬──┘
                                │      │       │
                                │      │       │
                            ┌───▼──────┴───┐   │
                            │              │   │
                            │              ◄───┘
                            │              │
                            │    subnet    │
                            │              │
                            │              │ ┌─A'─┐
                            │              │ │ u5 │
                            └──────────────┘ └────┘
"
echo "Look for the transaction confirmation in the Clarinet console in an
  upcoming block on the layer 1.

  🟩 invoked: ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.subnet::deposit-nft-asset(ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND.simple-nft-l1, u5, ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND) (ok true)
"
echo "We can also verify that the L2 miner has processed the deposit by looking
  for the txid in a deposit op in the L2 miner logs and 

  $ grep $txid ../subnet.log

"
grep $txid ../subnet.log

read
echo "################################################################################"
echo "Transfer the NFT on the L2 Subnet network"
echo "  $ node ./transfer_nft.js 1"
read
result=$(node ./transfer_nft.js 1)
if [ $? -ne 0 ]; then
  exit 1
fi
txid=$(extract_txid "$output")
if [ $? -ne 0 ]; then
  echo $txid
  exit 1
fi
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    stacks    │
                            │              │
                            │     ┌────────┤ ┌────┐
                            │     │ subnet │ │ u̶5̶ │
                            └───┬─┴────▲───┘ └────┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
             ┌────────┐     │              │ ┌─B'─┐
             │transfer├─────►    subnet    │ │ u5 │
             └────────┘     │              │ └────┘
                            │              │
                            │              │
                            └──────────────┘
"
echo "Look in the subnet miner log for confirmation of this transaction.

  $ grep $txid ../subnet.log
"
grep $txid ../subnet.log

read
echo "################################################################################"
echo "Withdraw the NFT from the L2 Subnet network"
echo "  $ node ./withdraw_nft_l2.js 0"
read
result=$(node ./withdraw_nft_l2.js 0)
if [ $? -ne 0 ]; then
  exit 1
fi
txid=$(extract_txid "$output")
if [ $? -ne 0 ]; then
  echo $txid
  exit 1
fi
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    stacks    │
                            │              │
                            │     ┌────────┤ ┌────┐
                            │     │ subnet │ │ u5 │
                            └───┬─┴────▲───┘ └────┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
           ┌──────────┐     │              │
           │ withdraw ├─────►    subnet    │
           └──────────┘     │              │
                            │              │
                            │              │
                            └──────────────┘
"
echo "Look in the subnet miner log for confirmation of this transaction.

  $ grep $txid ../subnet.log
"
grep $txid ../subnet.log
echo "We'll also want to find the withdrawal event in the log and record the
  block height, to be used in the L1 withdrawal.
  
    $ grep 'Parsed L2 withdrawal event' ../subnet.log
"
grep_res=$(grep 'Parsed L2 withdrawal event' ../subnet.log)
echo $grep_res
# extract the block height
height=$(echo $grep_res | sed -E 's/.*block_height: ([0-9]+),.*/\1/')

read
echo "################################################################################"
echo "Complete the withdrawal of the NFT on the L1 Stacks network"
echo "  $ node ./withdraw_nft_l1.js {WITHDRAWAL_BLOCK_HEIGHT} 0"
node ./withdraw_nft_l1.js $height 0
echo "
                            ┌──────────────┐
                            │              │
                            │              │
                            │              │
                            │   bitcoin    │
                            │              │
                            │              │
                            │              │
                            └───┬──────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │ ┌─B──┐
                            │    stacks    │ │ u5 │
                            │              │ └────┘
           ┌──────────┐     │     ┌────────┤
           │ withdraw ├─────┼─────► subnet │
           └──────────┘     └───┬─┴────▲───┘
                                │      │
                                │      │
                            ┌───▼──────┴───┐
                            │              │
                            │              │
                            │              │
                            │    subnet    │
                            │              │
                            │              │
                            │              │
                            └──────────────┘
"
echo "We can confirm this transaction in the clarinet console:
  🟩 invoked: ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.subnet::withdraw-nft-asset(u5, ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05...
"

read
echo "################################################################################"
echo "Verify the ownership of the NFT on the L1 Stacks network"
echo "  $ node ./verify.js"
node ./verify.js
echo "If all went well, this should match $ALT_USER_ADDR"

echo "

                        ┌─────────────────────────┐
                        │                         │
                        │                         │
                        │                         │
                        │       ┌┐       ┌┐       │
                        │       └┘       └┘       │
                        │                         │
                        │                         │
                        │     │             │     │
                        │     │             │     │
                        │     └─────────────┘     │
                        │                         │
                        │                         │
                        │                         │
                        └─────────────────────────┘
"

echo "All done! You can stop 'clarinet integrate' and 'subnet-node' now by pressing"
echo "  Ctrl+C in each of the corresponding terminals."
