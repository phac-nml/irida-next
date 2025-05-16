# frozen_string_literal: true

# Base root class for service related classes, scoped by group
class BaseGroupService < BaseService
  attr_accessor :group

  def initialize(group, user = nil, params = {})
    super(user, params.except(:group, :group_id))
    puts 'in basebase'
    @group = group
    puts @group
  end
end
