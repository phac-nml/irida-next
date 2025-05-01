# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Attachments
  # Component for rendering a table of Attachments
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # 📝 Define columns related to attachment metadata for sorting/filtering.
    METADATA_COLUMNS = %w[format type].freeze
    # 📝 Define columns related to the actual file data for sorting/filtering.
    FILE_DATA_COLUMNS = %w[filename byte_size].freeze

    # rubocop:disable Naming/MethodParameterName,Metrics/ParameterLists
    def initialize(
      attachments,
      pagy,
      q,
      namespace,
      render_individual_attachments,
      has_attachments,
      row_actions: false,
      abilities: {},
      empty: {},
      **system_arguments
    )
      @attachments = attachments
      @pagy = pagy
      @q = q
      @namespace = namespace
      @render_individual_attachments = render_individual_attachments
      @has_attachments = has_attachments
      @abilities = abilities
      @row_actions = row_actions
      @empty = empty
      # 🚀 Determine if any row actions are enabled for rendering the actions column.
      @renders_row_actions = @row_actions.any? { |_key, value| value }
      @system_arguments = system_arguments

      # 📝 Set the columns to be displayed in the table.
      @columns = columns
    end
    # rubocop:enable Naming/MethodParameterName,Metrics/ParameterLists

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
        args[:id] = 'attachments-table'
        args[:classes] = class_names(args[:classes], 'overflow-auto scrollbar')
        if @abilities[:select_attachments]
          args[:data] ||= {}
          args[:data][:controller] = 'selection'
          args[:data][:'selection-total-value'] = @pagy.count
          args[:data][:'selection-action-button-outlet'] = '.action-button'
        end
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container @2xl:flex @2xl:flex-col @3xl:shrink @3xl:min-h-0')
      }
    end

    def row_arguments(attachment)
      { tag: 'tr' }.tap do |args|
        args[:classes] =
          class_names('bg-white dark:bg-slate-800', 'border-b border-slate-200 dark:border-slate-700')
        args[:id] = dom_id(attachment)
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    def destroy_path(attachment_id)
      if @namespace.type == 'Group'
        group_attachment_new_destroy_path(
          attachment_id:
        )
      else
        namespace_project_attachment_new_destroy_path(
          attachment_id:
        )
      end
    end

    # 💡 Maps the display column name to the corresponding Ransack sort attribute name.
    # Handles specific mappings for metadata and file data columns.
    def sort_column_name(column)
      column_str = column.to_s
      case column_str
      when 'id'
        'puid' # 📝 Map display 'id' to the 'puid' attribute.
      when *METADATA_COLUMNS
        "metadata_#{column_str}" # 📝 Prefix metadata columns.
      when *FILE_DATA_COLUMNS
        "file_blob_#{column_str}" # 📝 Prefix file data columns (accessing via ActiveStorage blob).
      else
        column_str # 📝 Return the original column name if no specific mapping exists.
      end
    end

    private

    def columns
      %i[id filename format type byte_size created_at]
    end
  end
end
