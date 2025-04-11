# frozen_string_literal: true

module Viral
  # A component for displaying an empty state
  class EmptyStateComponent < Viral::Component
    attr_reader :title, :description

    def initialize(title:, description:, icon_name:)
      @title = title
      @description = description
      @icon_name = icon_name
    end

    def empty_icon
      return if @icon_name.blank?

      icon @icon_name, class: 'size-10'
    end
  end
end
