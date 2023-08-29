# frozen_string_literal: true

module GroupsList
  class GroupListTreeComponent < ViewComponent::Base
    attr_reader :parent, :groups, :path, :path_args, :collapsed, :limit

    def initialize(groups:, parent: nil, path: nil, path_args: {})
      @parent = parent
      @groups = groups
      @path = path
      @path_args = path_args
      @collapsed = true
      @limit = 10
    end

    def show_more
      @parent.present? && @groups.count > @limit
    end
  end
end
