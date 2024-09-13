# frozen_string_literal: true

require 'ransack/helpers/form_helper'

module Attachments
  # Component for rendering a table of Attachments
  class TableComponent < Component
    include Ransack::Helpers::FormHelper

    # rubocop:disable Naming/MethodParameterName,Metrics/ParameterLists
    def initialize(
      attachments,
      pagy,
      q,
      row_actions: false,
      abilities: {},
      empty: {},
      **system_arguments
    )
      @attachments = attachments
      @pagy = pagy
      @q = q
      @abilities = abilities
      @row_actions = row_actions
      @empty = empty
      @renders_row_actions = @row_actions.select { |_key, value| value }.count.positive?
      @system_arguments = system_arguments

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
          args[:data][:'selection-action-link-outlet'] = '.action-link'
        end
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container flex flex-col shrink min-h-0')
      }
    end

    def row_arguments(attachment)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = attachment.id
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end

    private

    def columns
      %i[id filename format type size created_at]
    end
  end
end
