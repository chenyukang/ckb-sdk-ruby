# frozen_string_literal: true

module CKB
  module Wallets
    class SudtWallet < NewWallet
      attr_accessor :sudt_type_script, :is_issuer

      def initialize(api:, from_addresses:, sudt_args:, collector_type: :default_scanner, mode: MODE::TESTNET, from_block_number: 0)
        super(api: api, from_addresses: from_addresses, collector_type: collector_type, mode: mode, from_block_number: from_block_number)
        @sudt_type_script = CKB::Types::Script.new(code_hash: CKB::Config.instance.sudt_info[:code_hash], args: sudt_args, hash_type: "data")
        @is_issuer = input_scripts.size == 1 && input_scripts.first.compute_hash == sudt_args
      end

      def generate(to_address, sudt_amount, output_info = {}, fee_rate = 1)
        data = CKB::Utils.generate_sudt_amount(sudt_amount)
        lock = CKB::AddressParser.new(to_address).parse.script
        output = CKB::Types::Output.new(lock: lock, type: sudt_type_script, capacity: 0)
        capacity = CKB::Utils.byte_to_shannon(output.calculate_bytesize(data))

        advance_generate(
          to_infos: {
            to_address => { capacity: capacity, type: sudt_type_script, data: data }
          },
          contexts: [output_info[:context]],
          fee_rate: fee_rate
        )
      end

      def advance_generate(to_infos:, contexts: [], fee_rate: 1)
        outputs = []
        outputs_data = []

        to_infos.each do |to_address, output_info|
          script = CKB::AddressParser.new(to_address).parse.script
          outputs << CKB::Types::Output.new(capacity: output_info[:capacity], lock: script, type: output_info[:type])
          outputs_data << (output_info[:data] || "0x")
        end

        if outputs.all? { |output| output.capacity > 0 }
          if is_issuer
            outputs << CKB::Types::Output.new(capacity: 0, lock: input_scripts.first, type: nil)
            outputs_data << "0x"
          else
            outputs << CKB::Types::Output.new(capacity: 0, lock: input_scripts.first, type: sudt_type_script)
            outputs_data << "0x#{'0' * 32}"
          end
        end

        transaction = CKB::Types::Transaction.new(
          version: 0, cell_deps: [], header_deps: [], inputs: [],
          outputs: outputs, outputs_data: outputs_data, witnesses: []
        )
        tx_generator = CKB::SudtTransactionGenerator.new(api, transaction)

        tx_generator.is_issuer = is_issuer
        tx_generator.generate(collector: collector, contexts: input_scripts.map(&:compute_hash).zip(contexts).to_h, fee_rate: fee_rate)
        tx_generator
      end

      def total_amount
        collector.select { |cell_meta| cell_meta.output.type && cell_meta.output.type.compute_hash == sudt_type_script.compute_hash }.map{ |cell_meta| CKB::Utils.sudt_amount!(cell_meta.output_data) }.sum
      end

      private

      def normal_cell?(cell_meta)
        cell_meta.output_data_len.zero? && cell_meta.output.type.nil?
      end

      def collector
        collector =
          if collector_type == :default_scanner
            search_keys = input_scripts.map { |script| CKB::Indexer::Types::SearchKey.new(script, "lock") }
            CKB::Collector.new(indexer_api).default_indexer(search_keys: search_keys)
          else
            raise "unsupported collector type"
          end

        Enumerator.new do |result|
          loop do
            begin
              cell_meta = collector.next
              if is_issuer ? normal_cell?(cell_meta) : (cell_meta.output.type == nil || cell_meta.output.type.compute_hash == sudt_type_script.compute_hash)
                result << cell_meta
              end
            rescue StopIteration
              break
            end
          end
        end
      end
    end
  end
end
