# frozen_string_literal: true

# Component for displaying a page header with title, subtitle and buttons
class PageHeaderComponent < ViewComponent::Base
  renders_one :icon, IconComponent
  renders_one :buttons

  def initialize(title:, subtitle:)
    @title = title
    @subtitle = subtitle
  end
end
