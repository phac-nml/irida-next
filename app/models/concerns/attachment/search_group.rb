# frozen_string_literal: true

# model to represent attachment search group
class Attachment::SearchGroup < AdvancedSearchGroup # rubocop:disable Style/ClassAndModuleChildren
  self.condition_class = Attachment::SearchCondition
end
