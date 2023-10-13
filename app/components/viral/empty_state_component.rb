# frozen_string_literal: true

module Viral
  # A component for displaying an empty state
  class EmptyStateComponent < Viral::Component
    attr_reader :title, :description, :icon_name

    def initialize(title:, description:, icon_name:)
      @title = title
      @description = description
      @icon_name = icon_name
    end
  end
end
