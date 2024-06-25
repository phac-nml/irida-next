# frozen_string_literal: true

module Members
  # Component for rendering a table of members
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName
    def initialize(q)
      @q = q
      @columns = columns
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('relative overflow-x-auto'),
        data: { turbo: :temporary }
      }
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    private

    def columns
      %i[user_email access_level namespace_name created_at expires_at]
    end
  end
end
