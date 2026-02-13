# frozen_string_literal: true

# Component for rendering a drop down that filters dynamically
class ComboboxComponent < Component
  def initialize(form:, field:, options:, **trigger_arguments)
    @trigger_id = form.field_id(field)
    @menu_id = "#{form.field_id(field)}_menu"
    @form = form
    @field = field
    @menu_options = create_menu(options)
    @selected_option = get_selected_option(options)
    @trigger_arguments = trigger_arguments
  end

  private

  def trigger_arguments # rubocop:disable Metrics/AbcSize
    { tag: 'input' }.deep_merge(@trigger_arguments).tap do |args|
      args[:autocomplete] = 'off'
      args[:id] = @trigger_id
      args[:type] = 'text'
      args[:value] = @selected_option[:name]
      args[:role] = 'combobox'
      args[:aria] ||= {}
      args[:aria][:autocomplete] = 'list'
      args[:aria][:expanded] = 'false'
      args[:aria][:controls] = @menu_id
      args[:data] ||= {}
      args[:data][:'combobox-target'] = 'trigger'
    end
  end

  def get_selected_option(options)
    fragment = Nokogiri::HTML.fragment(options)
    fragment.search('option').each do |option|
      return { name: option.text, value: option['value'] } if option.key?('selected')
    end
    { name: '', value: '' }
  end

  def create_menu(options)
    fragment = Nokogiri::HTML.fragment(options)
    fragment = create_menu_options(fragment)
    fragment = create_menu_grouped_options(fragment)
    ActiveSupport::SafeBuffer.new(fragment.to_html)
  end

  def create_menu_grouped_options(fragment) # rubocop:disable Metrics/MethodLength
    fragment.search('optgroup').each_with_index do |group, group_index|
      menu_group_option_id = "#{@menu_id}_group#{group_index}"
      menu_group = Nokogiri::XML::Node.new('div', fragment)
      menu_group['role'] = 'group'
      menu_group['aria-labelledby'] = menu_group_option_id
      menu_group_option = Nokogiri::XML::Node.new('div', menu_group)
      menu_group_option['id'] = menu_group_option_id
      menu_group_option['role'] = 'presentation'
      menu_group_option.content = group['label']
      menu_group.add_child(menu_group_option)
      group.children.each do |child|
        menu_group.add_child(child.dup)
      end
      group.replace(menu_group)
    end
    fragment
  end

  def create_menu_options(fragment)
    fragment.search('option').each_with_index do |option, option_index|
      menu_group_option = Nokogiri::XML::Node.new('div', fragment)
      menu_group_option['id'] = "#{@menu_id}_option#{option_index}"
      menu_group_option['role'] = 'option'
      menu_group_option['data-value'] = option['value']
      menu_group_option.content = option.text
      option.replace(menu_group_option)
    end
    fragment
  end
end
