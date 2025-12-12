# frozen_string_literal: true

# Component for rendering a drop down that filters dynamically
class SelectWithAutoCompleteComponent < Component
  def initialize(form:, field:, options:, **combobox_arguments)
    @combobox_id = form.field_id(field)
    @listbox_id = "#{form.field_id(field)}_listbox"
    @form = form
    @field = field
    @listbox_options = create_listbox(options)
    @selected_option = get_selected_option(options)
    @combobox_arguments = combobox_arguments
  end

  private

  def combobox_arguments # rubocop:disable Metrics/AbcSize
    { tag: 'input' }.deep_merge(@combobox_arguments).tap do |args|
      args[:autocomplete] = 'off'
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
      args[:style] = "anchor-name: --anchor-#{@listbox_id};"
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
      listbox_group_option.content = option.text
      option.replace(listbox_group_option)
    end
    fragment
  end
end
