# frozen_string_literal: true

module GroupsList
  # Component to render a collapsible tree of groups
  class GroupListTreeComponent < Component
    attr_reader :parent, :groups, :path, :path_args, :collapsed, :limit

    def initialize(groups:, parent: nil, path: nil, path_args: {}, limit: 10)
      @parent = parent
      @groups = groups
      @path = path
      @path_args = path_args
      @collapsed = true
      @limit = limit
    end

    def show_more
      @parent.present? && @groups.count > @limit
    end
  end
end
