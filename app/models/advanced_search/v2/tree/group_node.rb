# frozen_string_literal: true

module AdvancedSearch
  module V2
    module Tree
      # Immutable value object representing a boolean group (AND/OR) in a V2 query tree.
      class GroupNode
        attr_reader :combinator, :nodes

        def initialize(combinator: 'and', nodes: [])
          @combinator = combinator
          @nodes = nodes
        end

        def type = :group
      end
    end
  end
end
