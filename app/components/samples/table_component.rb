# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Samples
  # Component for rendering a table of Samples
  class TableComponent < Component
    include Ransack::Helpers::FormHelper
    include UrlHelpers

    # Number of sticky columns at @2xl breakpoint and above (2), 1 column below @2xl
    STICKY_COLUMN_COUNT = 2

    # Initial batch size for metadata field templates (deferred loading optimization)
    INITIAL_TEMPLATE_BATCH_SIZE = 20

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

      @metadata_fields = metadata_fields
      initialize_metadata_batches(metadata_fields)

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
      base_args[:data] ||= {}

      apply_virtual_scroll_data!(base_args)
      apply_selection_data!(base_args) if @abilities[:select_samples]
      base_args
    end

    # 🔄 Applies virtual-scroll controller and data attributes.
    #
    # @param args [Hash] arguments to mutate
    # @return [void]
    def apply_virtual_scroll_data!(args)
      args[:data][:controller] = 'virtual-scroll'
      args[:data][:'virtual-scroll-target'] = 'container'
      args[:data][:'virtual-scroll-metadata-fields-value'] = @metadata_fields.to_json
      args[:data][:'virtual-scroll-fixed-columns-value'] = @columns.to_json
      args[:data][:'virtual-scroll-sticky-column-count-value'] = STICKY_COLUMN_COUNT
      args[:data][:'virtual-scroll-sort-key-value'] = @sort_key || ''
    end

    # 🚀 Applies selection-related data attributes for interactive selection.
    # Adds accessibility and i18n-driven live region messages.
    #
    # @param args [Hash] arguments to mutate
    # @return [void]
    def apply_selection_data!(args)
      args[:data] ||= {}
      # Append to existing controller value
      existing_controller = args[:data][:controller] || ''
      args[:data][:controller] = [existing_controller, 'selection'].join(' ').strip
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

    def row_arguments(sample, row_index)
      { tag: 'tr' }.tap do |args|
        args[:classes] =
          class_names('bg-white dark:bg-slate-800', 'border-b border-slate-200 dark:border-slate-700')
        args[:id] = dom_id(sample)
        args[:role] = 'row'
        args[:aria] = { rowindex: @pagy.offset + row_index + 2 } # +2 for 1-based and header row
        args[:data] ||= {}
        args[:data][:sample_id] = sample.id
        args[:data][:'virtual-scroll-target'] = 'row'
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    private

    def initialize_metadata_batches(metadata_fields)
      if @namespace.is_a?(Namespaces::ProjectNamespace)
        @initial_metadata_fields = metadata_fields.take(INITIAL_TEMPLATE_BATCH_SIZE)
        @deferred_metadata_fields = metadata_fields.drop(INITIAL_TEMPLATE_BATCH_SIZE)
      else
        # Groups do not have a deferred templates endpoint, so render all upfront
        @initial_metadata_fields = metadata_fields
        @deferred_metadata_fields = []
      end
    end

    def columns
      columns = %i[puid name]
      columns << 'namespaces.puid' if @namespace.type == 'Group'
      columns += %i[created_at updated_at attachments_updated_at]
      columns
    end
  end
end
