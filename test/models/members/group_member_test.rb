# frozen_string_literal: true

require 'test_helper'

class GroupMemberTest < ActiveSupport::TestCase
  def setup
    @group_member = group_members(:group_one_james_doe)
  end

  test 'valid group member' do
    assert @group_member.valid?
  end


end
