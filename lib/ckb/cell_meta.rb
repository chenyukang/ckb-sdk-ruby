# frozen_string_literal: true

module CKB
  class CellMeta
    attr_reader :out_point, :output, :output_data_len, :cellbase, :api
    attr_writer :output_data

    def initialize(api:, out_point:, output:, output_data_len:, cellbase:)
      @api = api
      @out_point = out_point
      @output = output
      @output_data_len = output_data_len
      @cellbase = cellbase
    end

    def output_data
      @output_data ||= api.get_live_cell(out_point, true).cell.data.content
    end

    def ==(other)
      self.out_point.to_h == other.out_point.to_h &&
        self.output.to_h == other.output.to_h &&
        self.output_data_len == other.output_data_len &&
        self.cellbase == other.cellbase
    end
  end
end
