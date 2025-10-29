# frozen_string_literal: true

# Component for rendering a drop down that filters dynamically
class SelectWithAutoCompleteComponent < Component
  def initialize(form:, field:, options:, **input_arguments)
    @combobox_id = form.field_id(field)
    @listbox_id = 'listbox_id'
    @form = form
    @field = field
    @options = create_listbox(options) # TODO: validate?
    @selected_option = get_selected_option(options) # Assume there is only one selected option for now
    @input_arguments = input_arguments
  end

  private

  def input_arguments # rubocop:disable Metrics/AbcSize
    { tag: 'input' }.deep_merge(@input_arguments).tap do |args|
      args[:id] = @combobox_id
      args[:type] = 'text'
      args[:value] = @selected_option[:name]
      args[:role] = 'combobox'
      args[:aria] ||= {}
      args[:aria][:autocomplete] = 'list'
      args[:aria][:expanded] = 'false'
      args[:aria][:controls] = @listbox_id
      args[:data] ||= {}
      args[:data][:'select-with-auto-complete-target'] = 'combobox'
    end
  end

  def get_selected_option(options)
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
      id = "group#{group_index}"
      ul = Nokogiri::XML::Node.new('ul', fragment)
      ul['role'] = 'group'
      ul['aria-labelledby'] = id
      li = Nokogiri::XML::Node.new('li', ul)
      li['id'] = id
      li['role'] = 'presentation'
      li.inner_html = group['label']
      ul.add_child(li)
      group.children.each do |child|
        ul.add_child(child.dup)
      end
      group.replace(ul)
    end
    fragment
  end

  def create_listbox_options(fragment)
    fragment.search('option').each_with_index do |option, option_index|
      li = Nokogiri::XML::Node.new('li', fragment)
      li['id'] = "option#{option_index}"
      li['role'] = 'option'
      li['value'] = option['value']
      li.inner_html = option.text
      option.replace(li)
    end
    fragment
  end
end
