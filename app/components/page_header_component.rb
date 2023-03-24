# frozen_string_literal: true

# Component for displaying a page header with title, subtitle and buttons
class PageHeaderComponent < ViewComponent::Base
  renders_one :breadcrumbs
  renders_one :icon
  renders_one :buttons

  def initialize(title:, subtitle:)
    @title = title
    @subtitle = subtitle
  end
end
