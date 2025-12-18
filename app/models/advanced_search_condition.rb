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
    field.blank? && operator.blank? && Array(value).compact_blank.blank?
  end
end
