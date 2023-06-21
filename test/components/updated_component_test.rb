# frozen_string_literal: true

require 'test_helper'

class UpdatedComponentTest < ViewComponent::TestCase
  include ActionView::Helpers::DateHelper

  test 'renders custom description updated at time ago (less than a minute)' do
    render_inline(UpdatedComponent.new(description: 'Record updated',
                                       updated_at: Time.zone.now + 1))

    assert_text 'Record updated less than a minute ago'
  end

  test 'renders custom description updated at time ago (greater than a minute)' do
    render_inline(UpdatedComponent.new(description: 'Record updated',
                                       updated_at: Time.zone.now + 1000))

    assert_text 'Record updated 17 minutes ago'
  end

  test 'renders default updated at time ago (less than a minute)' do
    render_inline(UpdatedComponent.new(
                    updated_at: Time.zone.now + 1
                  ))

    assert_text 'Updated less than a minute ago'
  end

  test 'renders default updated at time ago (greater than a minute)' do
    render_inline(UpdatedComponent.new(
                    updated_at: Time.zone.now + 1000
                  ))

    assert_text 'Updated 17 minutes ago'
  end
end
