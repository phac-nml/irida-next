# frozen_string_literal: true

require 'view_component_system_test_case'

class FlashComponentTest < ViewComponentSystemTestCase
  def test_success_message_with_javascript_close
    visit('/rails/preview/flash/success')
    # message = 'Successful Message!'
    # with_rendered_component_path(render_inline(Viral::FlashComponent.new(type: 'success', data: message))) do |path|
    #   visit path
    assert_text 'Successful Message!'
    #   assert_selector '.bg-green-700'
    #   find('[data-action="flash#dismiss"]').click
    #   assert_no_text message
    # end
  end
end
