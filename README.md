## Setup

* Checkout the `mint-with-trait` branch of the [stacks-subnets repo](https://github.com/hirosystems/stacks-subnets), then build the subnet-node.

  ```sh
  git clone https://github.com/hirosystems/stacks-subnets.git
  cd stacks-subnets
  git checkout mint-with-trait
  cd testnet/stacks-node
  cargo build --features monitoring_prom,slog_json --release
  ```

* Clone this repository and launch a devnet:

  ```sh
  git clone https://github.com/obycode/nft-use-case.git
  cd nft-use-case
  clarinet integrate
  ```

* Verify that at block 5, the subnet contract is successfully deployed.

* Launch the subnet node

  ```sh
  subnet-node start --config ./Subnet.toml
  ```
