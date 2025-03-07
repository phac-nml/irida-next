# frozen_string_literal: true

# Executes context_crumbs in controllers after page action but before render, allowing crumbs to use updated vars
module BreadcrumbNavigation
  extend ActiveSupport::Concern

  private

  def render(*args)
    # Skip context_crumbs when rendering error pages
    context_crumbs unless args.first.to_s.include?('error')
    super
  end
end
