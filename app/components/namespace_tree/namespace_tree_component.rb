# frozen_string_literal: true

module NamespaceTree
  # Component to render a namespace tree
  class NamespaceTreeComponent < Component
    attr_reader :parent, :groups, :path, :path_args, :collapsed

    def initialize(groups:, type:, parent: nil, path: nil, path_args: {})
      @parent = parent
      @groups = groups
      @path = path
      @path_args = path_args
      @type = type
      @collapsed = true
    end
  end
end
