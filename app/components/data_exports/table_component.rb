# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module DataExports
  # Component for rendering a table of Data Exports
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName, Metrics/ParameterLists
    def initialize(
      has_data_exports,
      data_exports,
      pagy,
      q,
      empty: {},
      **system_arguments
    )
      @has_data_exports = has_data_exports
      @data_exports = data_exports
      @pagy = pagy
      @q = q
      @empty = empty
      @system_arguments = system_arguments

      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName, Metrics/ParameterLists

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
        args[:id] = 'data-exports-table'
        args[:classes] = class_names(args[:classes], 'overflow-auto scrollbar')
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container flex flex-col shrink min-h-0 data-turbo-temporary')
      }
    end

    def row_arguments(data_export)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = data_export.id
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    private

    def columns
      %i[id name export_type status created_at expires_at]
    end
  end
end
