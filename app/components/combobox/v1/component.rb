# frozen_string_literal: true

module Combobox
  module V1
    # Component for rendering a drop down that filters dynamically
    class Component < ::Component
      def initialize(form:, field:, options:, listbox_aria: nil, **combobox_arguments)
        @combobox_id = form.field_id(field)
        @listbox_id = "#{form.field_id(field)}_listbox"
        @form = form
        @field = field
        @listbox_options = create_listbox(options)
        @selected_option = selected_option(options)
        @combobox_arguments = combobox_arguments
        @listbox_aria = listbox_aria
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

      def listbox_aria_attributes
        return @listbox_aria if @listbox_aria.present?

        label = @combobox_arguments.dig(:aria, :label)
        label.present? ? { label: } : {}
      end

      def selected_option(options)
        fragment = Nokogiri::HTML.fragment(options)
        fragment.search('option').each do |option|
          return { name: option.text, value: option['value'] } if option.key?('selected')
        end
        { name: '', value: '' }
      end

      def create_listbox(options)
        fragment = Nokogiri::HTML.fragment(options)
        fragment = create_listbox_options(fragment)
        fragment = create_listbox_grouped_options(fragment)
        ActiveSupport::SafeBuffer.new(fragment.to_html)
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
          listbox_group_option['aria-disabled'] = 'true' if option.key?('disabled')
          listbox_group_option.content = option.text
          option.replace(listbox_group_option)
        end
        fragment
      end
    end
  end
end
