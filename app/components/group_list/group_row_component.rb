# frozen_string_literal: true

module GroupList
  # Represents a single row in the group list tree
  class GroupRowComponent < Component
    with_collection_parameter :group
    attr_reader :group, :collapse

    def initialize(group:, collapse: true)
      @group = group
      @collapse = collapse
    end
  end
end
