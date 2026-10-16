# frozen_string_literal: true

module Samples
  module Table
    module V2
      # Uses the same columns and cell renderers as the initial grid for every cursor page.
      class RowComponent < Component
        def initialize(sample, namespace, global_row_index:, **)
          super([sample], namespace, nil, virtual_pagination: { mode: :cursor, rows_url: '/',
                                                                page_size: 100 }, **)
          @global_row_index = global_row_index
        end
      end
    end
  end
end
