# frozen_string_literal: true

# model to represent sample search
class Sample::Search # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :groups, default: -> { [] }

  def groups_attributes=(attributes)
    @groups ||= []
    attributes.each_value do |group_params|
      @groups.push(Sample::Group.new(group_params))
    end
  end
end
