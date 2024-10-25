# frozen_string_literal: true

module Pathogen
  # @private
  # :nocov:
  class BaseComponent < Pathogen::Component
    SELF_CLOSING_TAGS = %i[area base br col embed hr img input link meta param source track
                           wbr].freeze

    def initialize(tag:, classes: nil, **system_arguments)
      @tag = tag
      @system_arguments = system_arguments

      @result = Pathogen::Classify.call(**@system_arguments.merge(classes: classes))

      @system_arguments[:'data-view-component'] = true

      # Add a test selector
      @content_tag_args = add_test_selector(@system_arguments).except(*Pathogen::Classify::Utilities::UTILITIES.keys)
    end

    def call
      if SELF_CLOSING_TAGS.include?(@tag)
        tag(@tag, @content_tag_args.merge(@result))
      else
        content_tag(@tag, content, @content_tag_args.merge(@result))
      end
    end
  end
end