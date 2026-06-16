# frozen_string_literal: true

require 'view_component_test_case'

class PathogenButtonToHelperTest < ViewComponentTestCase
  class ProbeComponent < Component
    def call
      pathogen_button_to(
        'Delete sample',
        '/samples/1',
        method: :delete,
        tone: :danger,
        emphasis: :outline
      )
    end
  end

  test 'renders pathogen button to form actions directly' do
    render_inline(ProbeComponent.new)

    assert_selector 'form[action="/samples/1"][method="post"]'
    assert_selector 'input[name="_method"][value="delete"]', visible: false
    assert_selector 'button[type="submit"]', text: 'Delete sample'
    assert_no_text 'scheme:'
  end
end
