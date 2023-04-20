# frozen_string_literal: true

module Viral
  # Base component to be inherited from
  class BaseComponent < Viral::Component
    attr_reader :tag, :content_tag_args

    def initialize(tag:, classes: nil, **system_arguments)
      @tag = tag
      @system_arguments = system_arguments
      @content_tag_args = prepare_arguments(@system_arguments.merge(classes:))
    end

    def call
      content_tag(tag, content, content_tag_args)
    end

    private

    def prepare_arguments(arguments)
      arguments[:class] = arguments[:classes]
      arguments.delete(:classes)
      arguments
    end
  end
end
