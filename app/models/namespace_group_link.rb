# frozen_string_literal: true

# entity class for NamespaceGroupLink
class NamespaceGroupLink < ApplicationRecord
  has_logidze
  acts_as_paranoid

  before_save :set_namespace_type

  belongs_to :group, class_name: 'Group'
  belongs_to :namespace, class_name: 'Namespace'

  validates :group_id, uniqueness: { scope: [:namespace_id] }

  validates :group_access_level, inclusion: { in: Member::AccessLevel.all_values_with_owner },
                                 presence: true

  private

  def set_namespace_type
    self.namespace_type = namespace.type
    true
  end
end
