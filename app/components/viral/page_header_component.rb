# frozen_string_literal: true

module Viral
  # Component for displaying a page header with title, subtitle and buttons
  class PageHeaderComponent < ViewComponent::Base
    attr_reader :title, :subtitle

    renders_one :icon, Viral::IconComponent
    renders_one :buttons

    def initialize(title:, subtitle:)
      @title = title
      @subtitle = subtitle
    end
  end
end
