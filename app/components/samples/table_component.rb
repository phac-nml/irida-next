# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Samples
  # Component for rendering a table of Samples
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName,Metrics/ParameterLists
    def initialize(
      samples,
      namespace,
      pagy,
      q,
      has_samples: true,
      abilities: {},
      metadata_fields: [],
      search_params: {},
      row_actions: {},
      empty: {},
      **system_arguments
    )
      @samples = samples
      @namespace = namespace
      @pagy = pagy
      @q = q
      @has_samples = has_samples
      @abilities = abilities
      @metadata_fields = metadata_fields
      @search_params = search_params
      @row_actions = row_actions
      @empty = empty
      @renders_row_actions = @row_actions.select { |_key, value| value }.count.positive?
      @system_arguments = system_arguments

      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName,Metrics/ParameterLists

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
        args[:id] = 'samples-table'
        args[:classes] = class_names(args[:classes], 'overflow-auto')
        if @abilities[:select_samples]
          args[:data] ||= {}
          args[:data][:controller] = 'selection'
          args[:data][:'selection-total-value'] = @pagy.count
          args[:data][:'selection-action-link-outlet'] = '.action-link'
        end
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container flex flex-col shrink min-h-0'),
        data: { 'turbo-prefetch': false }
      }
    end

    def row_arguments(sample)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = sample.id
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def select_samples_url(**)
      if @namespace.type == 'Group'
        select_group_samples_url(@namespace, **)
      else
        select_namespace_project_samples_url(@namespace.parent, @namespace.project, **)
      end
    end

    private

    def columns
      columns = %i[puid name]
      columns << :project if @namespace.type == 'Group'
      columns += %i[created_at updated_at attachments_updated_at]
      columns
    end
  end
end
