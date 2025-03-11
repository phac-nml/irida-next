# frozen_string_literal: true

# Executes context_crumbs in controllers after page action but before render, allowing crumbs to use updated vars
module BreadcrumbNavigation
  extend ActiveSupport::Concern

  private

  def render(*args)
    context_crumbs
    super
  end
end
