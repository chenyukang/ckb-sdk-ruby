# frozen_string_literal: true

module CKB
  class Address
    attr_reader :blake160 # pubkey hash
    alias pubkey_hash blake160

    PREFIX_MAINNET = "ckb"
    PREFIX_TESTNET = "ckt"

    DEFAULT_MODE = MODE::TESTNET

    TYPES = %w(01 02 04)
    CODE_HASH_INDEXES = %w(00 01)

    def initialize(blake160, mode: DEFAULT_MODE)
      @mode = mode
      @blake160 = blake160
      @prefix = self.class.prefix(mode: mode)
    end

    # Generates address assuming default lock script is used
    # payload = type(01) | code hash index(00) | pubkey blake160
    # see https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0021-ckb-address-format/0021-ckb-address-format.md for more info.
    def generate
      blake160_bin = [blake160[2..-1]].pack("H*")
      type = [TYPES[0]].pack("H*")
      code_hash_index = [CODE_HASH_INDEXES[0]].pack("H*")
      payload = type + code_hash_index + blake160_bin
      ConvertAddress.encode(@prefix, payload)
    end

    # Generates short payload format address
    # payload = type(01) | code hash index(01) | multisig
    # see https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0021-ckb-address-format/0021-ckb-address-format.md for more info.
    # @param [String] hash160
    # @return [String]
    def self.generate_short_payload_multisig_address(multisig_script_hash, mode: DEFAULT_MODE)
      prefix = prefix(mode: mode)
      blake160_bin = [multisig_script_hash[2..-1]].pack("H*")
      type = [TYPES[0]].pack("H*")
      code_hash_index = [CODE_HASH_INDEXES[1]].pack("H*")
      payload = type + code_hash_index + blake160_bin
      ConvertAddress.encode(prefix, payload)
    end

    # Generates full payload format address
    # payload = 0x02/0x04 | code_hash | args
    # see https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0021-ckb-address-format/0021-ckb-address-format.md for more info.
    # @param [String | Integer]  format_type
    # @param [String]  code_hash
    # @param [String[]]  args
    # @return [String]
    def self.generate_full_payload_address(format_type, code_hash, args, mode: DEFAULT_MODE)
      prefix = prefix(mode: mode)
      format_type = Utils.to_hex(format_type)[2..-1].rjust(2, '0')
      raise InvalidFormatTypeError.new("Invalid format type") unless TYPES[1..-1].include?(format_type)
      raise InvalidArgsTypeError.new("Args should be a hex string") unless CKB::Utils.valid_hex_string?(args)

      payload = [format_type].pack("H*") + CKB::Utils.hex_to_bin(code_hash) + CKB::Utils.hex_to_bin(args)

      CKB::ConvertAddress.encode(prefix, payload)
    end

    alias to_s generate

    # Parse address into lock assuming default lock script is used
    def parse(address)
      self.class.parse(address, mode: @mode)
    end

    def self.parse_short_payload_address(address, mode: DEFAULT_MODE)
      decoded_prefix, data = ConvertAddress.decode(address)
      format_type = data[0].unpack("H*").first
      code_hash_index = data[1].unpack("H*").first

      raise InvalidPrefixError.new("Invalid prefix") if decoded_prefix != prefix(mode: mode)
      raise InvalidFormatTypeError.new("Invalid format type") if format_type != TYPES[0]
      raise InvalidCodeHashIndexError.new("Invalid code hash index") unless CODE_HASH_INDEXES.include?(code_hash_index)

      CKB::Utils.bin_to_hex(data.slice(2..-1))
    end

    def self.parse_full_payload_address(address, mode: DEFAULT_MODE)
      decoded_prefix, data = ConvertAddress.decode(address)
      format_type = data[0].unpack("H*").first

      raise InvalidPrefixError.new("Invalid prefix") if decoded_prefix != prefix(mode: mode)
      raise InvalidFormatTypeError.new("Invalid format type") unless TYPES[1..-1].include?(format_type)

      offset = 1
      code_hash_size = 32
      code_hash = "0x#{data.slice(1..code_hash_size).unpack("H*").first}"
      offset += code_hash_size
      args = data[offset..-1]

      ["0x#{format_type}", code_hash, CKB::Utils.bin_to_hex(args)]
    end

    def self.parse(address, mode: DEFAULT_MODE)
      _decoded_prefix, data = ConvertAddress.decode(address)
      format_type = data[0].unpack("H*").first
      case format_type
      when "01"
        parse_short_payload_address(address, mode: mode)
      when "02", "04"
        parse_full_payload_address(address, mode: mode)
      else
        raise InvalidFormatTypeError.new("Invalid format type")
      end
    end

    def self.blake160(pubkey)
      pubkey = pubkey[2..-1] if pubkey.start_with?("0x")
      pubkey_bin = [pubkey].pack("H*")
      hash_bin = CKB::Blake2b.digest(pubkey_bin)
      Utils.bin_to_hex(hash_bin[0...20])
    end

    def self.hash160(pubkey)
      pubkey = pubkey[2..-1] if pubkey.start_with?("0x")
      pub_key_sha256 = Digest::SHA256.hexdigest(pubkey)

      "0x#{Digest::RMD160.hexdigest(pub_key_sha256)}"
    end

    def self.from_pubkey(pubkey, mode: DEFAULT_MODE)
      new(blake160(pubkey), mode: mode)
    end

    def self.prefix(mode: DEFAULT_MODE)
      case mode
      when MODE::TESTNET
        PREFIX_TESTNET
      when MODE::MAINNET
        PREFIX_MAINNET
      end
    end

    class InvalidFormatTypeError < StandardError; end
    class InvalidArgsTypeError < StandardError; end
    class InvalidArgSizeError < StandardError; end
    class InvalidPrefixError < StandardError; end
    class InvalidCodeHashIndexError < StandardError; end
  end
end
