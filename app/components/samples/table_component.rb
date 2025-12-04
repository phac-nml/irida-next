# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Samples
  # Component for rendering a table of Samples
  class TableComponent < Component
    include Ransack::Helpers::FormHelper
    include UrlHelpers

    # Maximum number of metadata fields to display regardless of sample count
    MAX_METADATA_FIELDS_SIZE = 200
    # Target maximum number of table cells (rows × columns) for optimal performance
    TARGET_MAX_CELLS = 2000

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      samples,
      namespace,
      pagy,
      has_samples: true,
      abilities: {},
      metadata_fields: [],
      search_params: {},
      empty: {},
      **system_arguments
    )
      @samples = samples
      @namespace = namespace
      @pagy = pagy
      @has_samples = has_samples
      @abilities = abilities

      @metadata_fields, @show_metadata_fields_size_warning, @metadata_fields_size_warning_message =
        apply_metadata_field_limit(metadata_fields)

      @search_params = search_params
      @empty = empty
      @system_arguments = system_arguments

      # use rpartition to split on the first space encountered from the right side
      # this allows us to sort by metadata fields which contain spaces
      @sort_key, _space, @sort_direction = search_params['sort'].rpartition(' ')

      @columns = columns
    end
    # rubocop:enable Metrics/ParameterLists

    # 📝 Returns the merged system arguments for the table wrapper.
    #
    # @return [Hash] system arguments for the table container
    def system_arguments
      base_args = { tag: 'div' }.deep_merge(@system_arguments)
      base_args[:id] = 'samples-table'
      base_args[:classes] = class_names(base_args[:classes], 'overflow-auto relative')
      apply_selection_data!(base_args) if @abilities[:select_samples]
      base_args
    end

    # 🚀 Applies selection-related data attributes for interactive selection.
    # Adds accessibility and i18n-driven live region messages.
    #
    # @param args [Hash] arguments to mutate
    # @return [void]
    def apply_selection_data!(args)
      args[:data] ||= {}
      args[:data][:controller] = 'selection'
      args[:data][:'selection-total-value'] = @pagy.count
      args[:data][:'selection-action-button-outlet'] = '.action-button'
      # i18n-driven live region messages
      # i18n-tasks-use t('components.samples.table_component.counts.status')
      args[:data][:'selection-count-message-one-value'] = I18n.t(
        'components.samples.table_component.counts.status.one'
      )
      args[:data][:'selection-count-message-other-value'] = I18n.t(
        'components.samples.table_component.counts.status.other'
      )
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container @2xl:flex @2xl:flex-col @3xl:shrink @3xl:min-h-0'),
        'data-controller' => 'editable-cell',
        'data-editable-cell-refresh-outlet' => "[data-controller='refresh']"
      }
    end

    def row_arguments(sample)
      { tag: 'tr' }.tap do |args|
        args[:classes] =
          class_names('bg-white dark:bg-slate-800', 'border-b border-slate-200 dark:border-slate-700')
        args[:id] = dom_id(sample)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    private

    def columns
      columns = %i[puid name]
      columns << 'namespaces.puid' if @namespace.type == 'Group'
      columns += %i[created_at updated_at attachments_updated_at]
      columns
    end

    def calculate_max_metadata_fields
      return MAX_METADATA_FIELDS_SIZE if @samples.empty?

      (TARGET_MAX_CELLS / @samples.size).floor.clamp(1, MAX_METADATA_FIELDS_SIZE)
    end

    def apply_metadata_field_limit(metadata_fields)
      max_fields = calculate_max_metadata_fields
      limited_fields = metadata_fields.take(max_fields)
      show_warning = metadata_fields.count > max_fields

      warning_message = if show_warning
                          I18n.t('components.samples.table_component.metadata_fields_size_warning',
                                 calculated_limit: max_fields,
                                 sample_count: @samples.size,
                                 target_max_cells: TARGET_MAX_CELLS)
                        end

      [limited_fields, show_warning, warning_message]
    end
  end
end
