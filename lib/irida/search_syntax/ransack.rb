# frozen_string_literal: true

require_relative 'ransack_transformer'

module Irida
  module SearchSyntax
    # IRIDA Next specific Ransack search syntax parser that supports metadata_fields
    class Ransack
      def initialize(text:, params: [], metadata_fields: [], sort: nil)
        @transformer = RansackTransformer.new(text:, params:, metadata_fields:, sort:)
        @parser = ::SearchSyntax::Parser.new
      end

      def parse_with_errors(text)
        @transformer.transform_with_errors(@parser.parse(text || '').value)
      end

      def parse(text)
        parse_with_errors(text)[0]
      end
    end
  end
end
