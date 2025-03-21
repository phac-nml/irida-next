# frozen_string_literal: true

require 'test_helper'
require 'test_helpers/markup_validation_helpers'

class ViewComponentTestCase < ViewComponent::TestCase
  include MarkupValidationHelpers

  def render_inline(component, **args, &)
    super
    assert_valid_markup(rendered_content)
  end

  def render_preview(name, params: {})
    result = self.class.name.gsub('::', '').gsub('Test', 'Preview')
    from = result.constantize
    super(name, from:, params:)
    w3c_validate result, content: rendered_content
  end
end
