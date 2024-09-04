# frozen_string_literal: true

module NamespaceTree
  # Component to render a namespace tree
  class NamespaceTreeComponent < Component
    attr_reader :parent, :namespaces, :path, :path_args, :collapsed, :flat

    # rubocop: disable Metrics/ParameterLists
    def initialize(namespaces:, type:, parent: nil, path: nil, path_args: {}, flat: false)
      @parent = parent
      @namespaces = namespaces
      @path = path
      @path_args = path_args
      @type = type
      @collapsed = true
      @flat = flat
    end

    # rubocop: enable Metrics/ParameterLists
  end
end
