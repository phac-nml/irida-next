# frozen_string_literal: true

require 'view_component_system_test_case'

module System
  class FlashComponentTest < ViewComponentSystemTestCase
    test 'success message with javascript close' do
      message = 'Successful Message!'
      with_rendered_component_path(render_inline(Viral::FlashComponent.new(type: 'success', data: message))) do |path|
        visit path
        assert_text message
        assert_selector '.bg-green-700'
        find('[data-action="flash#dismiss"]').click
        assert_no_text message
      end
    end
  end
end
