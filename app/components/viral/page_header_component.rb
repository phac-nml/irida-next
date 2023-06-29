# frozen_string_literal: true

module Viral
  # Component for displaying a page header with title, subtitle and buttons
  class PageHeaderComponent < Component
    attr_reader :avatar, :title, :subtitle

    renders_one :icon, Viral::IconComponent
    renders_one :buttons

    def initialize(title:, subtitle:, avatar: nil)
      @title = title
      @subtitle = subtitle
      @avatar = avatar
    end
  end
end
