# frozen_string_literal: true

require 'view_component_test_case'

class LiveRegionComponentTest < ViewComponentTestCase
  test 'renders with default attributes' do
    render_inline(LiveRegionComponent.new)

    assert_selector "span[role='status'][aria-live='polite'].sr-only"
  end

  test 'renders with polite politeness level' do
    render_inline(LiveRegionComponent.new(politeness: :polite))

    assert_selector "span[aria-live='polite']"
  end

  test 'renders with assertive politeness level' do
    render_inline(LiveRegionComponent.new(politeness: :assertive))

    assert_selector "span[aria-live='assertive']"
  end

  test 'renders with off politeness level' do
    render_inline(LiveRegionComponent.new(politeness: :off))

    assert_selector "span[aria-live='off']"
  end

  test 'defaults to polite when invalid politeness level provided' do
    render_inline(LiveRegionComponent.new(politeness: :invalid))

    assert_selector "span[aria-live='polite']"
  end

  test 'renders with default target for selection controller' do
    render_inline(LiveRegionComponent.new(controller: 'selection'))

    assert_selector "span[data-selection-target='status']"
  end

  test 'renders with custom target' do
    render_inline(LiveRegionComponent.new(target: 'formStatus', controller: 'form'))

    assert_selector "span[data-form-target='formStatus']"
  end

  test 'renders empty when no content provided' do
    render_inline(LiveRegionComponent.new)

    assert_selector 'span:empty'
  end

  test 'renders without controller data attribute when controller not specified' do
    render_inline(LiveRegionComponent.new)

    # Check that common controller targets don't exist
    assert_no_selector 'span[data-selection-target]'
    assert_no_selector 'span[data-form-target]'
  end

  test 'includes sr-only class for screen reader visibility' do
    render_inline(LiveRegionComponent.new)

    assert_selector 'span.sr-only'
  end

  test 'renders with role status' do
    render_inline(LiveRegionComponent.new)

    assert_selector "span[role='status']"
  end

  test 'renders without aria-atomic by default' do
    render_inline(LiveRegionComponent.new)

    assert_no_selector 'span[aria-atomic]'
  end

  test 'renders with aria-atomic when specified' do
    render_inline(LiveRegionComponent.new(atomic: true))

    assert_selector "span[aria-atomic='true']"
  end

  test 'renders with custom data attributes' do
    render_inline(LiveRegionComponent.new(data: { custom: 'value' }))

    assert_selector "span[data-custom='value']"
  end

  test 'merges custom data attributes with controller target' do
    render_inline(LiveRegionComponent.new(controller: 'selection', data: { custom: 'value' }))

    assert_selector "span[data-selection-target='status'][data-custom='value']"
  end

  test 'allows overriding target via target parameter' do
    render_inline(LiveRegionComponent.new(controller: 'selection', target: 'customStatus'))

    assert_selector "span[data-selection-target='customStatus']"
  end
end
