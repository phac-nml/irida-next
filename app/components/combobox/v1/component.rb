# frozen_string_literal: true

module Combobox
  module V1
    # Component for rendering a drop down that filters dynamically
    class Component < ::Component # rubocop:disable Metrics/ClassLength
      renders_many :options, ::Combobox::V1::OptionComponent

      def initialize(form:, field:, options: nil, **combobox_arguments)
        @combobox_id = form.field_id(field)
        @listbox_id = "#{form.field_id(field)}_listbox"
        @form = form
        @field = field
        @options_argument = options
        @listbox_options = ActiveSupport::SafeBuffer.new
        @selected_option = { name: '', value: '' }
        @combobox_arguments = combobox_arguments
      end

      def before_render
        option_markup = source_option_markup
        @listbox_options = create_listbox(option_markup)
        @selected_option = selected_option(option_markup)
      end

      private

      def combobox_arguments # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        { tag: 'input' }.deep_merge(@combobox_arguments).tap do |args|
          args[:autocomplete] = 'off'
          args[:id] = @combobox_id
          args[:type] = 'text'
          args[:value] = @selected_option[:name]
          args[:role] = 'combobox'
          disabled = args.delete(:disabled) == true
          args[:aria] ||= {}
          args[:aria][:disabled] = 'true' if disabled
          args[:readonly] = true if disabled
          args[:aria][:autocomplete] = 'list'
          args[:aria][:expanded] = 'false'
          args[:aria][:controls] = @listbox_id
          args[:data] ||= {}
          args[:data][:'combobox--v1-target'] = 'combobox'
        end
      end

      def selection_present?
        @selected_option[:value].present?
      end

      def combobox_disabled?
        @combobox_arguments[:disabled] == true
      end

      def selected_option(options_markup)
        fragment = Nokogiri::HTML.fragment(options_markup.to_s)

        selected_native_option(fragment) || selected_role_option(fragment) || empty_selection
      end

      def selected_native_option(fragment)
        option = fragment.search('option').find { |node| node.key?('selected') }
        selection_from_node(option, value_attribute: 'value')
      end

      def selected_role_option(fragment)
        option = fragment.search('[role="option"]').find do |node|
          node['data-selected'] == 'true' || node['aria-selected'] == 'true'
        end
        selection_from_node(option, value_attribute: 'data-value')
      end

      def selection_from_node(node, value_attribute:)
        return if node.blank?

        { name: node['data-label'] || node.text, value: node[value_attribute].to_s }
      end

      def empty_selection
        { name: '', value: '' }
      end

      def create_listbox(options_markup)
        fragment = Nokogiri::HTML.fragment(options_markup.to_s)
        fragment = create_listbox_options(fragment)
        fragment = create_listbox_grouped_options(fragment)
        fragment = ensure_option_ids(fragment)
        ActiveSupport::SafeBuffer.new(fragment.to_html)
      end

      def source_option_markup
        if options?
          ActiveSupport::SafeBuffer.new(options.join)
        else
          @options_argument.to_s
        end
      end

      def ensure_option_ids(fragment)
        fragment.search('[role="option"]').each_with_index do |option, option_index|
          option['id'] = "#{@listbox_id}_option#{option_index}"
        end
        fragment
      end

      def create_listbox_grouped_options(fragment) # rubocop:disable Metrics/MethodLength
        fragment.search('optgroup').each_with_index do |group, group_index|
          listbox_group_option_id = "#{@listbox_id}_group#{group_index}"
          listbox_group = Nokogiri::XML::Node.new('div', fragment)
          listbox_group['role'] = 'group'
          listbox_group['aria-labelledby'] = listbox_group_option_id
          listbox_group_option = Nokogiri::XML::Node.new('div', listbox_group)
          listbox_group_option['id'] = listbox_group_option_id
          listbox_group_option['role'] = 'presentation'
          listbox_group_option.content = group['label']
          listbox_group.add_child(listbox_group_option)
          group.children.each do |child|
            listbox_group.add_child(child.dup)
          end
          group.replace(listbox_group)
        end
        fragment
      end

      def create_listbox_options(fragment)
        fragment.search('option').each_with_index do |option, option_index|
          listbox_group_option = Nokogiri::XML::Node.new('div', fragment)
          listbox_group_option['id'] = "#{@listbox_id}_option#{option_index}"
          listbox_group_option['role'] = 'option'
          listbox_group_option['data-value'] = option['value']
          listbox_group_option['data-label'] = option.text
          listbox_group_option['aria-disabled'] = 'true' if option.key?('disabled')
          listbox_group_option.content = option.text
          option.replace(listbox_group_option)
        end
        fragment
      end
    end
  end
end
