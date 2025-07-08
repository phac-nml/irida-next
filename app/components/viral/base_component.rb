# frozen_string_literal: true

module Viral
  # Base component to be inherited from
  class BaseComponent < Viral::Component
    SELF_CLOSING_TAGS = %w[area base br col embed hr img input keygen link meta param source track wbr].freeze

    def initialize(tag:, classes: nil, **system_arguments)
      @tag = tag
      @system_arguments = system_arguments
      @content_tag_args = prepare_arguments(@system_arguments.merge(classes:))
    end

    def call
      if SELF_CLOSING_TAGS.include?(@tag)
        tag(@tag, @content_tag_args, true)
      else
        content_tag(@tag, content, @content_tag_args)
      end
    end

    private

    def prepare_arguments(arguments)
      arguments[:class] = arguments[:classes]
      arguments.delete(:classes)
      arguments
    end
  end
end
