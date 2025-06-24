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
        pathogen_icon(ICON::GROUPS, size: :md, color: :subdued, class: 'mr-2')
      elsif @namespace.project_namespace?
        pathogen_icon(ICON::PROJECTS, size: :md, color: :subdued, class: 'mr-2')
      end
    end
  end
end
