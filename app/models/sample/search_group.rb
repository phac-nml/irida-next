# frozen_string_literal: true

# model to represent sample search group
class Sample::SearchGroup < AdvancedSearchGroup # rubocop:disable Style/ClassAndModuleChildren
  self.condition_class = Sample::SearchCondition
end
