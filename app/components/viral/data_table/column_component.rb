# frozen_string_literal: true

module Viral
  module DataTable
    # Section component for a dialog.
    class ColumnComponent < Viral::Component
      attr_reader :title, :show_link, :sticky, :sorted, :sort_url, :pill, :time_ago, :time, :metadata

      def initialize(title: '', show_link: false, sticky: false, pill: false, time_ago: false, time: false, metadata: false, **system_arguments,
                     &block)
        @title = title
        @show_link = show_link
        @sticky = sticky
        @pill = pill
        @time_ago = time_ago
        @time = time
        @metadata = metadata
        @block = block
        @system_arguments = system_arguments
      end

      def header_arguments
        {
          tag: 'th',
          classes: class_names('px-3 py-3', @sticky && 'sticky left-0 bg-slate-50 dark:bg-slate-900')
        }
      end

      def system_arguments
        { tag: 'td' }.deep_merge(@system_arguments).tap do |args|
          args[:classes] = class_names('px-3 py-3', @sticky && 'sticky left-0 bg-slate-50 dark:bg-slate-900')
        end
      end
    end
  end
end
