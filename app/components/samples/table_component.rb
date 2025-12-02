# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Samples
  # Component for rendering a table of Samples
  class TableComponent < Component # rubocop:disable Metrics/ClassLength
    include Ransack::Helpers::FormHelper
    include UrlHelpers

    # Maximum number of metadata fields to display regardless of sample count
    MAX_METADATA_FIELDS_SIZE = 200
    # Target maximum number of table cells (rows × columns) for optimal performance
    TARGET_MAX_CELLS = 2000

    # Number of sticky columns at @2xl breakpoint and above (2), 1 column below @2xl
    STICKY_COLUMN_COUNT = 2

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

      @metadata_fields, @show_metadata_fields_size_warning =
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
    def before_render
      return unless @show_metadata_fields_size_warning

      can_edit = @abilities[:edit_sample_metadata]
      @metadata_fields_size_warning_message = build_metadata_fields_size_warning_message(can_edit_metadata: can_edit)
    end

    def system_arguments
      base_args = { tag: 'div' }.deep_merge(@system_arguments)
      base_args[:id] = 'samples-table'
      base_args[:classes] = class_names(base_args[:classes], 'overflow-auto relative')
      base_args[:data] ||= {}

      # Add virtual-scroll controller and data attributes
      base_args[:data][:controller] = 'virtual-scroll'
      base_args[:data][:'virtual-scroll-target'] = 'container'
      base_args[:data][:'virtual-scroll-metadata-fields-value'] = @metadata_fields.to_json
      base_args[:data][:'virtual-scroll-fixed-columns-value'] = @columns.to_json
      base_args[:data][:'virtual-scroll-sticky-column-count-value'] = STICKY_COLUMN_COUNT
      base_args[:data][:'virtual-scroll-sort-key-value'] = @sort_key || ''

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

    def row_arguments(sample)
      { tag: 'tr' }.tap do |args|
        args[:classes] =
          class_names('bg-white dark:bg-slate-800', 'border-b border-slate-200 dark:border-slate-700')
        args[:id] = dom_id(sample)
        args[:data] ||= {}
        args[:data][:sample_id] = sample.id
        args[:data][:'virtual-scroll-target'] = 'row'
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
      [limited_fields, show_warning]
    end

    def build_metadata_fields_size_warning_message(can_edit_metadata: false)
      params = warning_interpolation_params

      if can_edit_metadata
        warning_message_with_link(params)
      else
        I18n.t('components.samples.table_component.metadata_fields_size_warning', **params)
      end
    end

    def warning_interpolation_params
      {
        calculated_limit: calculate_max_metadata_fields,
        sample_count: @samples.size,
        target_max_cells: TARGET_MAX_CELLS
      }
    end

    def warning_message_with_link(params)
      link_markup = create_template_link

      # Using html_safe because we're interpolating a link_to helper result
      # which is already sanitized by Rails. This is safe as the link_markup
      # contains no user-provided content - only the translated link text.
      I18n.t(
        'components.samples.table_component.metadata_fields_size_warning_with_link',
        **params, create_template_link: link_markup
      ).html_safe
    end

    def create_template_link
      helpers.link_to(
        I18n.t('components.samples.table_component.create_template_link'),
        metadata_template_url,
        class: 'font-semibold underline hover:no-underline',
        data: { turbo_frame: 'top' }
      )
    end
  end
end
