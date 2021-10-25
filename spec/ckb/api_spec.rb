# frozen_string_literal: true

RSpec.describe CKB::API do
  Types = CKB::Types

  before do
    skip "not test rpc" if ENV["SKIP_RPC_TESTS"]
  end

  let(:api) { CKB::API.new }
  let(:lock_hash) { "0xe94e4b509d5946c54ea9bc7500af12fd35eebe0d47a6b3e502127f94d34997ac" }
  let(:block_h) do
    { uncles: [],
      proposals: [],
      transactions: [{ version: "0x0",
                       cell_deps: [],
                       header_deps: [],
                       inputs: [{ previous_output: { tx_hash: "0x0000000000000000000000000000000000000000000000000000000000000000", index: "0xffffffff" },
                                  since: "0x1" }],
                       outputs: [],
                       outputs_data: [],
                       witnesses: ["0x590000000c00000055000000490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8011400000036c329ed630d6ce750712a477543672adab57f4c00000000"] }],
      header: { compact_target: "0x20010000",
                number: "0x1",
                parent_hash: "0xe49352ee4984694d88eb3c1493a33d69d61c786dc5b0a32c4b3978d4fad64379",
                nonce: "0x7622c91cd47ca43fa63f7db0ee0fd3ef",
                timestamp: "0x16d7ad5d9de",
                transactions_root: "0x29c04a85c4b686ec8a78615d193d64d4416dbc428f9e4631f27c62419926110f",
                proposals_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
                extra_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
                version: "0x0",
                epoch: "0x3e80001000000",
                dao: "0x04d0a006e1840700df5d55f5358723001206877a0b00000000e3bad4847a0100" } }
  end

  let(:normal_tx) do
    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0xace5ea83c478bb866edf122ff862085789158f5cbff155b7bb5f13058555b708",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        }
      ],
      "header_deps": [],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0x3ac0a667dc308a78f38c75cbeedfdea9247bbd67e727e1c153a4aa1a2afb28d8",
            "index": "0x0"
          },
          "since": "0x0"
        }
      ],
      "outputs": [
        {
          "capacity": "0x174876e800",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0xe2193df51d78411601796b35b17b4f8f2cd85bd0",
            "hash_type": "type"
          },
          "type": nil
        },
        {
          "capacity": "0x123057115561",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x36c329ed630d6ce750712a477543672adab57f4c",
            "hash_type": "type"
          },
          "type": nil
        }
      ],
      "outputs_data": %w[
        0x
        0x
      ],
      "witnesses": ["0x5500000010000000550000005500000041000000fd8d32a3e1a4276d479379357d8dda72f68672db9a21919bdc6f24d7b91cc6de5e7f76b835b9038303d9cae171ab47428eabdfa310d09254b8fadae19026605300"]
    }
  end

  it "genesis block" do
    expect(api.genesis_block).to be_a(Types::Block)
  end

  it "genesis block hash" do
    expect(api.genesis_block_hash).to be_a(String)
  end

  it "get block" do
    genesis_block_hash = api.get_block_hash(0)
    result = api.get_block(genesis_block_hash)
    expect(result).to be_a(Types::Block)
  end

  it "get block by number" do
    block_number = 0
    result = api.get_block_by_number(block_number)
    expect(result).to be_a(Types::Block)
    expect(result.header.number).to eq block_number
  end

  it "get tip header" do
    result = api.get_tip_header
    expect(result).to be_a(Types::BlockHeader)
    expect(result.number > 0).to be true
  end

  it "get tip block number" do
    result = api.get_tip_block_number
    expect(result > 0).to be true
  end

  it "get transaction" do
    tx = api.genesis_block.transactions.first
    result = api.get_transaction(tx.hash)
    expect(result).to be_a(Types::TransactionWithStatus)
    expect(result.transaction.hash).to eq tx.hash
  end

  it "get live cell with data" do
    out_point = Types::OutPoint.new(tx_hash: "0x45d086fe064ada93b6c1a6afbfd5e441d08618d326bae7b7bbae328996dfd36a", index: 0)
    result = api.get_live_cell(out_point, true)
    expect(result).not_to be nil
  end

  it "get live cell without data" do
    out_point = Types::OutPoint.new(tx_hash: "0x45d086fe064ada93b6c1a6afbfd5e441d08618d326bae7b7bbae328996dfd36a", index: 0)
    result = api.get_live_cell(out_point)
    expect(result).not_to be nil
  end

  it "send empty transaction" do
    tx = Types::Transaction.new(
      version: 0,
      cell_deps: [],
      inputs: [],
      outputs: []
    )

    expect do
      api.send_transaction(tx)
    end.to raise_error(CKB::RPCError, /:code=>-3/)
  end

  it "should raise ArgumentError when outputs_validator is invalid" do
    expect do
      api.send_transaction(normal_tx, "something")
    end.to raise_error(ArgumentError, "Invalid outputs_validator, outputs_validator should be `default` or `passthrough`")
  end

  it "should not raise ArgumentError when outputs_validator is valid" do
    expect do
      api.send_transaction(normal_tx, "passthrough")
    end.not_to raise_error(ArgumentError, "Invalid outputs_validator, outputs_validator should be `default` or `passthrough`")
  end

  it "should not raise ArgumentError when outputs_validator is nil" do
    expect do
      api.send_transaction(normal_tx)
    end.not_to raise_error(ArgumentError, "Invalid outputs_validator, outputs_validator should be `default` or `passthrough`")
  end

  it "get current epoch" do
    result = api.get_current_epoch
    expect(result).not_to be nil
    expect(result).to be_a(Types::Epoch)
  end

  it "get epoch by number" do
    number = 0
    result = api.get_epoch_by_number(number)
    expect(result).to be_a(Types::Epoch)
    expect(result.number).to eq number
  end

  it "local node info" do
    result = api.local_node_info
    expect(result).to be_a(Types::LocalNode)
  end

  it "get verbose raw_tx_pool info" do
    result = api.get_raw_tx_pool(true)
    expect(result).to be_a(Types::TxPoolVerbosity)
  end

  it "get raw_tx_pool info" do
    result = api.get_raw_tx_pool
    expect(result).to be_a(Types::TxPoolIds)
  end

  it "get consensus" do
    result = api.get_consensus
    expect(result).to be_a(Types::Consensus)
  end

  it "tx pool info" do
    result = api.tx_pool_info
    expect(result).not_to be nil
    expect(result.to_h.keys.sort).to eq %i[pending proposed orphan last_txs_updated_at min_fee_rate total_tx_cycles total_tx_size tip_hash tip_number].sort
  end

  # need to clear the tx pool first
  it "clear tx pool" do
    wallet = CKB::Wallet.from_hex(api, "0xd00c06bfd800d27397002dca6fb0993d5ba6399b4238b2f29ee9deb97593d2bc", indexer_api: CKB::Indexer::API.new("http://localhost:8116"))
    wallet.send_capacity("ckt1qyqqg2rcmvgwq9ypycgqgmp5ghs3vcj8vm0s2ppgld", 1000 * 10**8, fee: 1100)
    tx_pool_info = api.tx_pool_info
    expect(tx_pool_info.pending).to eq 1
    api.clear_tx_pool
    tx_pool_info = api.tx_pool_info
    expect(tx_pool_info.pending).to eq 0
  end

  # need to mine more than 12 blocks locally
  it "get block economic state" do
    block_hash = api.get_block_hash(12)
    result = api.get_block_economic_state(block_hash)
    expect(result).not_to be nil
    expect(result.to_h.keys.sort).to eq %i[finalized_at issuance miner_reward txs_fee].sort
  end

  it "get peers" do
    result = api.get_peers
    expect(result).not_to be nil
  end

  it "tx pool info" do
    result = api.tx_pool_info
    expect(result).to be_a(Types::TxPoolInfo)
    expect(result.pending >= 0).to be true
  end

  it "get blockchain info" do
    result = api.get_blockchain_info
    expect(result).to be_a(Types::ChainInfo)
    expect(result.epoch >= 0).to be true
  end

  it "dry run transaction" do
    tx = Types::Transaction.new(
      version: 0,
      cell_deps: [],
      inputs: [],
      outputs: []
    )

    result = api.dry_run_transaction(tx)
    expect(result).to be_a(Types::DryRunResult)
    expect(result.cycles >= 0).to be true
  end

  it "get block header" do
    block_hash = api.get_block_hash(1)
    result = api.get_header(block_hash)
    expect(result).to be_a(Types::BlockHeader)
    expect(result.number > 0).to be true
  end

  it "get block header by number" do
    block_number = 1
    result = api.get_header_by_number(block_number)
    expect(result).to be_a(Types::BlockHeader)
    expect(result.number).to eq block_number
  end

  it "set ban" do
    params = ["192.168.0.2", "insert", 1_840_546_800_000, true, "test set_ban rpc"]
    result = api.set_ban(*params)
    expect(result).to be nil
  end

  it "get banned addresses" do
    result = api.get_banned_addresses
    expect(result).not_to be nil
    expect(result).to all(be_a(Types::BannedAddress))
  end

  it "ping peers" do
    result = api.ping_peers
    expect(result).to be_nil
  end

  it "get transaction proof" do
	  proof_hash = {
      "block_hash": "0x7978ec7ce5b507cfb52e149e36b1a23f6062ed150503c85bbf825da3599095ed",
      "proof": {
        "indices": ["0x0"],
        "lemmas": []
      },
      "witnesses_root": "0x2bb631f4a251ec39d943cc238fc1e39c7f0e99776e8a1e7be28a03c70c4f4853"
    }
    stub = instance_double("CKB::API")
    allow(stub).to receive(:get_transaction_proof).with(tx_hashes: ["0xa4037a893eb48e18ed4ef61034ce26eba9c585f15c9cee102ae58505565eccc3"]) do
      CKB::Types::TransactionProof.from_h(proof_hash)
    end
  end

  it "verify transaction proof" do
    proof_hash = {
      "block_hash": "0x7978ec7ce5b507cfb52e149e36b1a23f6062ed150503c85bbf825da3599095ed",
      "proof": {
          "indices": ["0x0"],
          "lemmas": []
      },
      "witnesses_root": "0x2bb631f4a251ec39d943cc238fc1e39c7f0e99776e8a1e7be28a03c70c4f4853"
    }
    stub = instance_double("CKB::API")
    allow(stub).to receive(:verify_transaction_proof).with(proof_hash) do
	    ["0xa4037a893eb48e18ed4ef61034ce26eba9c585f15c9cee102ae58505565eccc3"]
    end
  end

  it "clear banned addresses" do
	  result = api.clear_banned_addresses
	  expect(result).to be_nil
  end

  context "miner APIs" do
    it "get_block_template" do
      result = api.get_block_template
      expect(result).not_to be nil
    end

    it "get_block_template with bytes_limit" do
      result = api.get_block_template(bytes_limit: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "get_block_template with proposals_limit" do
      result = api.get_block_template(proposals_limit: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "get_block_template with max_version" do
      result = api.get_block_template(max_version: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "get_block_template with bytes_limit, proposals_limit and max_version" do
      result = api.get_block_template(max_version: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "submit_block should return block hash" do
      block_h[:header][:parent_hash] = api.genesis_block_hash
      block = Types::Block.from_h(block_h)
      result = api.submit_block(work_id: "test", raw_block_h: block.to_raw_block_h)
      expect(result).to be_a(String)
    end

    it "generate_block_with_template should return block hash" do
	    block_template = api.get_block_template
	    result = api.generate_block_with_template(block_template)
	    expect(result).to be_a(String)
    end
  end

  context "batch request" do
    it "should return corresponding record" do
      result = api.batch_request(["get_block_by_number", 1], ["get_block_by_number", 2], ["get_block_by_number", 3])
      expect(result.count).to eq 3
    end

    it "should raise RPCError when param is invalid" do
      expect do
        api.batch_request(%w[get_block_by_number 1], %w[get_block_by_number 2], %w[get_block_by_number 3])
      end.to raise_error CKB::RPCError
    end
  end

  it "sync_state should return sync_state model" do
    result = api.sync_state
    expect(result).to be_a(Types::SyncState)
  end

  it "set_network_active should return nil" do
    result = api.set_network_active(true)
    expect(result).to be_nil
  end

  it "add_node should return nil" do
    result = api.add_node(peer_id: "QmUsZHPbjjzU627UZFt4k8j6ycEcNvXRnVGxCPKqwbAfQS", address: "/ip4/192.168.2.100/tcp/8114")
    expect(result).to be_nil
  end

  it "remove_node should return nil" do
    result = api.remove_node("QmUsZHPbjjzU627UZFt4k8j6ycEcNvXRnVGxCPKqwbAfQS")
    expect(result).to be_nil
  end
end
