#!/bin/bash

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

read
echo "################################################################################"
echo "Publish the NFT contract to the L2 Subnet network"
echo "  $ node ./publish_tx.js simple-nft-l2 ../contracts-l2/simple-nft-l2.clar 2 0"
read
node ./publish_tx.js simple-nft-l2 ../contracts-l2/simple-nft-l2.clar 2 0
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

read
echo "################################################################################"
echo "Deposit the NFT into the L2 Subnet network"
echo "  $ node ./deposit_nft.js 2"
read
node ./deposit_nft.js 2
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

read
echo "################################################################################"
echo "Transfer the NFT on the L2 Subnet network"
echo "  $ node ./transfer_nft.js 1"
read
node ./transfer_nft.js 1
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

read
echo "################################################################################"
echo "Withdraw the NFT from the L2 Subnet network"
echo "  $ node ./withdraw_nft_l2.js 0"
read
node ./withdraw_nft_l2.js 0
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

read
echo "################################################################################"
echo "Complete the withdrawal of the NFT on the L1 Stacks network"
echo "  $ node ./withdraw_nft_l1.js {WITHDRAWAL_BLOCK_HEIGHT} 0"
read -p "What is the block height? " height
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

read
echo "################################################################################"
echo "Verify the ownership of the NFT on the L1 Stacks network"
echo "  $ node ./verify.js"
node ./verify.js
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
