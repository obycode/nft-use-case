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
  subnet-node start --config ./Subnet.toml
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
