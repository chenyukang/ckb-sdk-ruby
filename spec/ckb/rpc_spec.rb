# frozen_string_literal: true
RSpec.describe CKB::RPC do
  before do
    skip "not test rpc" if ENV["SKIP_RPC_TESTS"]
  end
  let(:raw_block_h) do
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
  let(:rpc) { CKB::RPC.new }
  let(:lock_hash) { "0xd0e22f863da970a3ff51a937ae78ba490bbdcede7272d658a053b9f80e30305d" }
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
      "outputs_data": [
        "0x",
        "0x"
      ],
      "witnesses": ["0x5500000010000000550000005500000041000000fd8d32a3e1a4276d479379357d8dda72f68672db9a21919bdc6f24d7b91cc6de5e7f76b835b9038303d9cae171ab47428eabdfa310d09254b8fadae19026605300"]
    }
  end

  it "genesis block" do
    result = rpc.genesis_block
    expect(result).not_to be nil
    expect(result[:header][:number]).to eq "0x0"
  end

  it "genesis block hash" do
    result = rpc.genesis_block_hash
    expect(result).not_to be nil
  end

  it "get block" do
    genesis_block_hash = rpc.get_block_hash(0)
    result = rpc.get_block(genesis_block_hash)
    expect(result).not_to be nil
    expect(result[:header][:hash]).to eq genesis_block_hash
  end

  it "get block by number" do
    result = rpc.get_block_by_number(0)
    expect(result).not_to be nil
    expect(result[:header][:number]).to eq "0x0"
  end

  it "get tip header" do
    result = rpc.get_tip_header
    expect(result).not_to be nil
    expect(result[:number].hex > 0).to be true
  end

  it "get tip block number" do
    result = rpc.get_tip_block_number
    expect(result.hex > 0).to be true
  end

  it "get transaction" do
    tx = rpc.genesis_block[:transactions].first
    result = rpc.get_transaction(tx[:hash])
    expect(result).not_to be nil
    expect(result[:transaction][:hash]).to eq tx[:hash]
  end

  it "get live cell with data" do
    out_point = {
      tx_hash: "0x45d086fe064ada93b6c1a6afbfd5e441d08618d326bae7b7bbae328996dfd36a",
      index: "0x0"
    }
    result = rpc.get_live_cell(out_point, true)
    expect(result).not_to be nil
  end

  it "get live cell without data" do
    out_point = {
      tx_hash: "0x45d086fe064ada93b6c1a6afbfd5e441d08618d326bae7b7bbae328996dfd36a",
      index: "0x0"
    }
    result = rpc.get_live_cell(out_point, false)
    expect(result).not_to be nil
  end

  it "send empty transaction" do
    tx = {
      version: 0,
      cell_deps: [],
      inputs: [],
      outputs: []
    }

    expect do
      rpc.send_transaction(tx)
    end.to raise_error(CKB::RPCError, /:code=>-3/)
  end

  it "should raise ArgumentError when outputs_validator is invalid" do
    expect do
      rpc.send_transaction(normal_tx, "something")
    end.to raise_error(ArgumentError, "Invalid outputs_validator, outputs_validator should be `default` or `passthrough`")
  end

  it "should not raise ArgumentError when outputs_validator is valid" do
    expect do
      rpc.send_transaction(normal_tx, "passthrough")
    end.not_to raise_error(ArgumentError, "Invalid outputs_validator, outputs_validator should be `default` or `passthrough`")
  end

  it "should not raise ArgumentError when outputs_validator is nil" do
    expect do
      rpc.send_transaction(normal_tx)
    end.not_to raise_error(ArgumentError, "Invalid outputs_validator, outputs_validator should be `default` or `passthrough`")
  end

  it "local node info" do
    result = rpc.local_node_info
    expect(result).not_to be nil
    expect(result[:addresses].empty?).not_to be true
    expect(result[:node_id].empty?).not_to be true
  end

  it "get epoch by number" do
    number = 0
    result = rpc.get_epoch_by_number(number)
    expect(result).to be_a(Hash)
    expect(result[:number].hex).to eq number
  end

  it "tx pool info" do
    result = rpc.tx_pool_info
    expect(result).not_to be nil
    expect(result.keys.sort).to eq %i(pending proposed orphan last_txs_updated_at min_fee_rate total_tx_cycles total_tx_size tip_hash tip_number).sort
  end

  # need to mine more than 12 blocks locally
  it "get block economic state" do
    block_hash = rpc.get_block_hash(12)
    result = rpc.get_block_economic_state(block_hash)
    expect(result).not_to be nil
    expect(result.keys.sort).to eq %i(finalized_at issuance miner_reward txs_fee).sort
  end

  it "get block header" do
    block_hash = rpc.get_block_hash(1)
    result = rpc.get_header(block_hash)
    expect(result[:number].hex > 0).to be true
  end

  it "get block header by number" do
    block_number = 1
    result = rpc.get_header_by_number(block_number)
    expect(result[:number].hex).to eq block_number
  end

  it "set ban" do
    params = ["192.168.0.2", "insert", 1_840_546_800_000, true, "test set_ban rpc"]
    result = rpc.set_ban(*params)
    expect(result).to be nil
  end

  it "get banned addresses" do
    result = rpc.get_banned_addresses
    expect(result).not_to be nil
  end

  context "miner RPCs" do
    it "get_block_template" do
      result = rpc.get_block_template
      expect(result).not_to be nil
    end

    it "get_block_template with bytes_limit" do
      result = rpc.get_block_template(1000)
      expect(result).not_to be nil
    end

    it "get_block_template with proposals_limit" do
      result = rpc.get_block_template(1000)
      expect(result).not_to be nil
    end

    it "get_block_template with max_version" do
      result = rpc.get_block_template(1000)
      expect(result).not_to be nil
    end

    it "get_block_template with bytes_limit, proposals_limit and max_version" do
      result = rpc.get_block_template(1000)
      expect(result).not_to be nil
    end

    # must use real data
    it "submit_block" do
      raw_block_h[:header][:parent_hash] = rpc.genesis_block_hash
      result = rpc.submit_block("test", raw_block_h)
      expect(result).not_to be nil
    end
  end

  context "batch request" do
    it "should return corresponding record" do
      result = rpc.batch_request(["get_block_by_number", 1], ["get_block_by_number", 2], ["get_block_by_number", 3])
      expect(result.count).to eq 3
    end

    it "should raise RPCError when param is invalid" do
      expect {
        rpc.batch_request(%w[get_block_by_number 1], %w[get_block_by_number 2], %w[get_block_by_number 3])
      }.to raise_error CKB::RPCError
    end
  end
end
