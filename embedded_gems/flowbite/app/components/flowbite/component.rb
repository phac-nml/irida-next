# frozen_string_literal: true

module Flowbite
  # @private
  # :nocov:
  class Component < ViewComponent::Base
    include Flowbite::FetchOrFallbackHelper
    include Flowbite::TestSelectorHelper

    INVALID_ARIA_LABEL_TAGS = %i[div span p].freeze

    def check_denylist(denylist = [], **arguments)
      return arguments unless should_raise_error?

      unpacked_denylist = unpack_denylist(denylist)
      violations = find_violations(unpacked_denylist, arguments)

      raise_violation_error(violations, unpacked_denylist) if violations.any?

      arguments
    end

    def validate_arguments(tag:, denylist_name: :system_arguments_denylist, **arguments)
      deny_single_argument(:class, 'Use `classes` instead.', **arguments)

      if (denylist = arguments[denylist_name])
        check_denylist(denylist, **arguments)

        # Remove :system_arguments_denylist key and any denied keys from system arguments
        arguments.except!(denylist_name)
        arguments.except!(*denylist.keys.flatten)
      end

      deny_aria_label(tag: tag, arguments: arguments)

      arguments
    end

    def deny_single_argument(key, help_text, **arguments)
      raise ArgumentError, "`#{key}` is an invalid argument. #{help_text}" \
        if should_raise_error? && arguments.key?(key)

      arguments.except!(key)
    end

    def deny_aria_label(tag:, arguments:)
      return arguments.except!(:skip_aria_label_check) if arguments[:skip_aria_label_check]
      return if arguments[:role]
      return unless INVALID_ARIA_LABEL_TAGS.include?(tag)

      deny_aria_key(
        :label,
        "Don't use `aria-label` on `#{tag}` elements. See https://www.tpgi.com/short-note-on-aria-label-aria-labelledby-and-aria-describedby/",
        **arguments
      )
    end

    def deny_aria_key(key, help_text, **arguments)
      raise ArgumentError, help_text if should_raise_aria_error? && aria(key, arguments)
    end

    private

    def unpack_denylist(denylist)
      denylist.each_with_object({}) do |(keys, value), memo|
        keys.each { |key| memo[key] = value }
      end
    end

    def find_violations(unpacked_denylist, arguments)
      unpacked_denylist.keys & arguments.keys
    end

    def raise_violation_error(violations, unpacked_denylist)
      message = build_violation_message(violations, unpacked_denylist)
      raise(ArgumentError, message)
    end

    def build_violation_message(violations, unpacked_denylist)
      message = "Found #{violations.count} #{'violation'.pluralize(violations)}:"
      violations.each do |violation|
        message += "\n The #{violation} argument is not allowed here. #{unpacked_denylist[violation]}"
      end
      message
    end
  end
end
