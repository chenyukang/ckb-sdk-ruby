# frozen_string_literal: true

module CKB
  module Serializers
    module StructSerializer
      include BaseSerializer

      private

      def layout
        body
      end
    end
  end
end
