# frozen_string_literal: true

require 'test_helper'
require 'devise/test/controller_helpers'
require 'test_helpers/markup_validation_helpers'

class ViewComponentTestCase < ViewComponent::TestCase
  include Devise::Test::ControllerHelpers
  include MarkupValidationHelpers

  def before_setup
    @request = vc_test_request
    @response = ActionDispatch::TestResponse.new
    @controller = vc_test_controller
    super
  end

  setup do
    vc_test_controller.request.env['devise.mapping'] ||= Devise.mappings[:user]
  end

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
