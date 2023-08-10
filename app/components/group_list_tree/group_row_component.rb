# frozen_string_literal: true

module GroupListTree
  # Represents a single row in the group list tree
  class GroupRowComponent < Component
    with_collection_parameter :group

    def initialize(group:)
      @group = group
    end
  end
end
