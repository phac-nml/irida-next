# frozen_string_literal: true

require 'test_helper'

class UpdatedComponentTest < ViewComponent::TestCase
  include ActionView::Helpers::DateHelper

  test 'renders updated at time ago (less than a minute)' do
    render_inline(UpdatedComponent.new(description: 'Updated',
                                       updated_at: distance_of_time_in_words(Time.zone.now, Time.zone.now + 1)))

    assert_text 'Updated less than a minute ago'
  end

  test 'renders updated at time ago (greater than a minute)' do
    render_inline(UpdatedComponent.new(description: 'Updated',
                                       updated_at: distance_of_time_in_words(Time.zone.now, Time.zone.now + 1000)))

    assert_text 'Updated 17 minutes ago'
  end
end
