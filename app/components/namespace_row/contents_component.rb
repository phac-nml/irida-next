# frozen_string_literal: true

module NamespaceRow
  # Namespace Row Contents component
  class ContentsComponent < Component
    include NamespacePathHelper

    def initialize(namespace:, icon_size: :small, search_params: nil)
      @namespace = namespace
      @icon_size = icon_size
      @search_params = search_params
    end

    def avatar_icon
      if @namespace.group_namespace?
        :squares_2x2
      elsif @namespace.project_namespace?
        :rectangle_stack
      end
    end
  end
end
