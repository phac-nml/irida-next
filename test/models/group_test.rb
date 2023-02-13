# frozen_string_literal: true

require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  def setup
    @group = groups(:group_one)
  end

  test 'valid group' do
    assert @group.valid?
  end
end
