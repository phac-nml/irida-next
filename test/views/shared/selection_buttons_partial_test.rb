# frozen_string_literal: true

require 'test_helper'

class SelectionButtonsPartialTest < ActionView::TestCase
  test 'over-limit select all remains focusable and exposes its disabled state' do
    render_selection_buttons(total_count: 50_001)

    assert_select 'button#select-all-button[data-pathogen--tooltip-target="trigger"]', count: 1 do |button|
      assert_equal 'true', button.first['aria-disabled']
      assert_equal 'button', button.first['type']
      assert_nil button.first['disabled']
      assert_nil button.first['form']
      assert button.first['aria-describedby'].present?
    end
    assert_select 'span[role="group"][tabindex="0"]', count: 0
    assert_select 'div[role="tooltip"]', count: 1
  end

  test 'select all submits normally at the selection limit' do
    render_selection_buttons(total_count: 50_000)

    assert_select 'button#select-all-button[type="submit"][form="select-all-form"]', count: 1 do |button|
      assert_nil button.first['aria-disabled']
    end
    assert_select 'div[role="tooltip"]', count: 0
  end

  private

  def render_selection_buttons(total_count:)
    render partial: 'shared/selection_buttons',
           locals: {
             url: '/samples/select',
             total_count:,
             select_form_fields: { select: 'on' }
           }
  end
end
