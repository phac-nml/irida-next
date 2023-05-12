# frozen_string_literal: true

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  def setup
    @sample = samples(:sample1)
  end

  test 'valid sample' do
    assert @sample.valid?
  end
end
