# frozen_string_literal: true

module NamespaceTree
  # Component to render a namespace tree
  class NamespaceTreeComponent < Component
    attr_reader :collapsed, :icon_size, :namespaces, :parent, :path, :path_args, :render_flat_list, :search_params

    # rubocop: disable Metrics/ParameterLists
    def initialize(namespaces:, type:, parent: nil, path: nil, path_args: {}, render_flat_list: false,
                   search_params: nil, icon_size: :small)
      @parent = parent
      @namespaces = namespaces
      @path = path
      @path_args = path_args
      @type = type
      @collapsed = true
      @render_flat_list = render_flat_list
      @search_params = search_params
      @icon_size = icon_size
    end

    # rubocop: enable Metrics/ParameterLists
  end
end
