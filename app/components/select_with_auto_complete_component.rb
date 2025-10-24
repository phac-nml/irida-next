# frozen_string_literal: true

# Component for rendering a drop down that filters dynamically
class SelectWithAutoCompleteComponent < Component
  def initialize(label:, combobox_id:, listbox_id:, options:)
    @label = label
    @combobox_id = combobox_id
    @listbox_id = listbox_id
    @options = replace(options) # TODO: validate?
  end

  private

  def replace(options)
    fragment = Nokogiri::HTML.fragment(options)
    fragment = replace_options(fragment)
    fragment = replace_groups(fragment)
    ActiveSupport::SafeBuffer.new(fragment.to_html)
  end

  def replace_groups(fragment) # rubocop:disable Metrics/MethodLength
    fragment.search('optgroup').each_with_index do |group, group_index|
      # TODO: handle selected
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

  def replace_options(fragment)
    fragment.search('option').each_with_index do |option, option_index|
      # TODO: handle selected
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
