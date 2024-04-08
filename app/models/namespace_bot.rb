# frozen_string_literal: true

# entity class for NamespaceBot
class NamespaceBot < ApplicationRecord
  has_logidze
  acts_as_paranoid

  belongs_to :user, class_name: 'User'
  belongs_to :namespace, class_name: 'Namespace'

  validates :user_id, uniqueness: { scope: [:namespace_id] }
end
