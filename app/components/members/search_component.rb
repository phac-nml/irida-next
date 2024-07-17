# frozen_string_literal: true

module Members
  # Component for rendering the search box for a table of members
  class SearchComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName
    def initialize(q, tab, namespace)
      @q = q
      @tab = tab
      @namespace = namespace
    end
    # rubocop:enable Naming/MethodParameterName

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('flex', 'flex-row-reverse')
      }
    end

    def members_url
      if @namespace.type == 'Group'
        group_members_url
      else
        namespace_project_members_url
      end
    end
  end
end
