# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module MetadataTemplates
  # Component for rendering a table of metadata templates
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName
    def initialize(metadata_templates, namespace, pagy, q, row_actions)
      @namespace = namespace
      @metadata_templates = metadata_templates
      @pagy = pagy
      @q = q
      @row_actions = row_actions
      @renders_row_actions = @row_actions.any? { |_key, value| value }
      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('relative overflow-x-auto')
      }
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    private

    def columns
      %i[name description created_by_email created_at updated_at]
    end
  end
end
