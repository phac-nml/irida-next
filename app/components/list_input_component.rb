# frozen_string_literal: true

# View component for displaying a list within an input box
class ListInputComponent < Component
  attr_reader :list_input_form_name, :show_description

  def initialize(list_input_form_name:, show_description: true, **input_arguments)
    @list_input_form_name = list_input_form_name
    @show_description = show_description
    @input_arguments = input_arguments
  end

  def input_arguments
    { tag: 'input' }.deep_merge(@input_arguments).tap do |args|
      args[:type] = 'text'
      args[:name] = @list_input_form_name
      args[:autofocus] = true
      args[:classes] = class_names(args[:classes], 'bg-transparent border-none grow')
      args[:aria] ||= {}
      args[:aria][:label] = t(:'components.list_input.description')
      args[:data] ||= {}
      args[:data][:action] = '
        keydown->list-filter#handleInput
        paste->list-filter#handlePaste
        turbo:morph-element->list-filter#idempotentConnect
      '
      args[:data][:'list-filter-target'] = 'input'
    end
  end
end
