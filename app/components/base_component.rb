# frozen_string_literal: true

# Base class for all components that require a tag and classes
# Example:
#   BaseComponent.new(tag: :div, classes: "bg-red-500")
#   BaseComponent.new(tag: :div, classes: "bg-red-500", data: { controller: "my-controller" })
class BaseComponent < Component
  def initialize(tag:, classes: nil, **system_arguments)
    @tag = tag
    @system_arguments = system_arguments
    @content_tag_args = prepare_arguments(@system_arguments.merge(classes:))
  end

  def call
    content_tag(@tag, content, @content_tag_args)
  end

  private

  def prepare_arguments(arguments)
    arguments[:class] = arguments[:classes]
    arguments.delete(:classes)
    arguments
  end
end
