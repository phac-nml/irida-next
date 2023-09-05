# frozen_string_literal: true

module GroupsList
  # Component to render a collapsible tree of groups
  class GroupListTreeComponent < Component
    attr_reader :parent, :groups, :path, :path_args, :collapsed

    def initialize(groups:, parent: nil, path: nil, path_args: {})
      @parent = parent
      @groups = groups
      @path = path
      @path_args = path_args
      @collapsed = true
    end
  end
end
