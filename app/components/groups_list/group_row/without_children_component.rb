# frozen_string_literal: true

class GroupsList::GroupRow::WithoutChildrenComponent < ViewComponent::Base
  def initialize(group:, path: nil, path_args: {})
    @group = group
    @path = path
    @path_args = path_args
  end
end
