# frozen_string_literal: true

module Pathogen
  module DataGrid
    # Column definition for DataGridComponent
    #
    # == Public API
    #
    # @param label [String] Column header label.
    # @param key [Symbol, String, nil] Hash key lookup when no block is provided.
    # @param width [Numeric, String, nil] Column width (numeric values become "px").
    # @param align [Symbol, String, nil] Alignment class suffix (e.g. :left, :center, :right).
    # @param sticky [Boolean, nil] Explicitly enable/disable sticky behavior.
    # @param sticky_left [Numeric, String, nil] Left offset
    #   (numeric values become "px"; strings allow CSS units);
    #   can enable sticky without width.
    # @param header_content [String, Proc, nil] Custom header content to replace the label.
    # @param system_arguments [Hash] Additional HTML attributes for the cell.
    # @yieldparam row [Hash, Array, Object] Row data for the current cell.
    # @yieldparam index [Integer] Column index.
    #
    # @note Sticky columns require either `width:` or `sticky_left:` to be applied.
    #   If both are missing, the grid disables sticky for that column.
    class ColumnComponent < Pathogen::Component
      attr_accessor :sticky, :sticky_left
      attr_reader :label, :key, :width, :align

      # rubocop:disable Metrics/ParameterLists
      def initialize(label:, key: nil, width: nil, align: nil, sticky: nil, sticky_left: nil, header_content: nil,
                     **system_arguments, &block)
        # rubocop:enable Metrics/ParameterLists
        @label = label
        @key = key
        @width = width
        @align = align
        @sticky = sticky
        @sticky_left = sticky_left
        @header_content = header_content
        @system_arguments = system_arguments
        @block = block
      end

      def header_cell_attributes
        attributes_for(header: true)
      end

      def body_cell_attributes
        attributes_for(header: false)
      end

      def render_value(row, index)
        return @block.call(row, index) if @block

        value_for(row, index)
      end

      def render_header
        return @header_content.call if @header_content.respond_to?(:call)
        return @header_content if @header_content.present?

        @label
      end

      def default_header_label?
        @header_content.blank?
      end

      def normalize_width!
        return if @width.blank?
        return @width = "#{@width}px" if @width.is_a?(Numeric)

        @width
      end

      def width_px
        match = @width.to_s.strip.match(/\A(\d+(?:\.\d+)?)px\z/)
        return unless match

        match[1].to_f
      end

      private

      def attributes_for(header:)
        classes = ['pathogen-data-grid__cell', @system_arguments[:class]]
        classes << (header ? 'pathogen-data-grid__cell--header' : 'pathogen-data-grid__cell--body')
        classes << 'pathogen-data-grid__cell--sticky' if @sticky
        classes << "pathogen-data-grid__cell--align-#{@align}" if @align

        styles = []
        styles << "--pathogen-data-grid-col-width: #{@width};" if @width
        if @sticky
          sticky_left_value = @sticky_left.is_a?(Numeric) ? "#{@sticky_left}px" : @sticky_left
          styles << "--pathogen-data-grid-sticky-left: #{sticky_left_value};"
        end

        { class: class_names(*classes), style: styles.join(' ') }
      end

      def value_for(row, index)
        return row[index] if row.is_a?(Array)
        return row[@key] if @key && row.is_a?(Hash) && row.key?(@key)

        row[@key.to_s] if @key && row.is_a?(Hash)
      end
    end
  end
end
