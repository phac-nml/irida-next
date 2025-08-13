# frozen_string_literal: true

module NamespaceRow
  # Namespace Row Contents component
  class ContentsComponent < Component
    include NamespacePathHelper

    def initialize(namespace:, full_name: false, icon_size: :small, search_params: nil)
      @namespace = namespace
      @full_name = full_name
      @icon_size = icon_size
      @search_params = search_params
    end

    def avatar_icon
      if @namespace.group_namespace?
        pathogen_icon(ICON::GROUPS, size: :md, color: :subdued)
      elsif @namespace.project_namespace?
        pathogen_icon(ICON::PROJECTS, size: :md, color: :subdued)
      end
    end
  end
end
