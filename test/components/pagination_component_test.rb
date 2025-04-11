# frozen_string_literal: true

require 'test_helper'

class PaginationComponentTest < ViewComponent::TestCase
  test 'renders next link only' do
    render_inline PaginationComponent.new(
      prev_url: nil,
      next_url: '/-/projects?page=2',
      info: '<span class="pagy-info">Displaying items <b>1-20</b> of <b>114</b> in total</span>'
    )

    assert_no_selector 'button.cursor-not-allowed', text: I18n.t('viral.pagy.pagination_component.previous')
    assert_selector 'a', text: I18n.t('viral.pagy.pagination_component.next')
  end

  test 'renders previous link only' do
    render_inline PaginationComponent.new(
      prev_url: '/-/projects?page=6',
      next_url: nil,
      info: '<span class="pagy-info">Displaying items <b>101-114</b> of <b>114</b> in total</span>'
    )

    assert_selector 'a', text: I18n.t('viral.pagy.pagination_component.previous')
    assert_no_selector 'button.cursor-not-allowed', text: I18n.t('viral.pagy.pagination_component.next')
  end

  test 'renders both links' do
    render_inline PaginationComponent.new(
      prev_url: '/-/projects?page=6',
      next_url: '/-/projects?page=2',
      info: '<span class="pagy-info">Displaying items <b>101-114</b> of <b>114</b> in total</span>'
    )

    assert_selector 'a', text: I18n.t('viral.pagy.pagination_component.previous')
    assert_selector 'a', text: I18n.t('viral.pagy.pagination_component.next')
  end

  test 'renders disabled previous link' do
    render_inline PaginationComponent.new(
      prev_url: nil,
      next_url: '/-/projects?page=2',
      info: '<span class="pagy-info">Displaying items <b>1-20</b> of <b>114</b> in total</span>'
    )

    assert_selector 'span.cursor-not-allowed.text-slate-600.bg-slate-100',
                    text: I18n.t('viral.pagy.pagination_component.previous')
  end

  test 'renders disabled next link' do
    render_inline PaginationComponent.new(
      prev_url: '/-/projects?page=6',
      next_url: nil,
      info: '<span class="pagy-info">Displaying items <b>101-114</b> of <b>114</b> in total</span>'
    )

    assert_selector 'span.cursor-not-allowed.text-slate-600.bg-slate-100',
                    text: I18n.t('viral.pagy.pagination_component.next')
  end
end
