# frozen_string_literal: true

module GroupList
  # Represents a single row in the group list tree
  class GroupRowComponent < Component
    with_collection_parameter :group
    attr_reader :group, :collapse, :path, :path_args

    def initialize(group:, collapse: true, path: nil, path_args: {})
      @group = group
      @collapse = collapse
      @path = path
      @path_args = path_args
    end
  end
end
