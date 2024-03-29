# frozen_string_literal: true

module Viral
  # Component for displaying a page header with title, subtitle and buttons
  class PageHeaderComponent < Component
    attr_reader :title, :subtitle

    renders_one :icon
    renders_one :buttons

    def initialize(title:, id: nil, subtitle: nil)
      @title = title
      @id = id
      @subtitle = subtitle
    end
  end
end
