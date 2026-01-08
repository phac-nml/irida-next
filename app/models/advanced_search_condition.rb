# frozen_string_literal: true

# Shared advanced search functionality for SearchCondition form objects.
#
# A SearchCondition stores a single search criterion with field, operator, and value.
class AdvancedSearchCondition
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :field
  attribute :operator
  attribute :value

  def empty?
    field.blank? && operator.blank? && value_empty?
  end

  private

  def value_empty?
    return value.none?(&:nil?) if value.is_a?(Array)

    value.blank?
  end
end
