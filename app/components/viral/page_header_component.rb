# frozen_string_literal: true

module Viral
  # Component for displaying a page header with title, subtitle and buttons
  class PageHeaderComponent < Component
    attr_reader :title, :subtitle, :id, :id_color

    renders_one :icon
    renders_one :buttons

    def initialize(title:, id: nil, subtitle: nil, id_color: :primary)
      @title = title
      @id = id
      @subtitle = subtitle
      @id_color = id_color
    end
  end
end
