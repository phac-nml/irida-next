# frozen_string_literal: true

module Members
  # Component for rendering a table of members
  class TableComponent < Component
    include Ransack::Helpers::FormHelper
    include MembersHelper

    # rubocop:disable Naming/MethodParameterName
    def initialize(namespace, members, q, current_user, abilities)
      @namespace = namespace
      @members = members
      @q = q
      @current_user = current_user
      @abilities = abilities
      @columns = columns
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('relative overflow-x-auto'),
        data: { turbo: :temporary }
      }
    end

    def row_arguments(member)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = dom_id(member)
      end
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
