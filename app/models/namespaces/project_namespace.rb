# frozen_string_literal: true

module Namespaces
  # Namespace for Projects
  class ProjectNamespace < Namespace
    has_one :project, inverse_of: :namespace, foreign_key: :namespace_id, dependent: :destroy
    has_many :users, through: :project_members
    has_many :project_members, foreign_key: :namespace_id, inverse_of: :namespace,
                               class_name: 'Members::ProjectMember', dependent: :destroy
    has_many :owners,
             -> { where(members: { access_level: Member::AccessLevel::OWNER }) },
             through: :project_members,
             source: :user

    def self.sti_name
      'Project'
    end
  end
end
