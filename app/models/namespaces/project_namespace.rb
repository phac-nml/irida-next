# frozen_string_literal: true

module Namespaces
  # Namespace for Projects
  class ProjectNamespace < Namespace
    has_one :project, inverse_of: :namespace, foreign_key: :namespace_id, dependent: :destroy

    def self.sti_name
      'Project'
    end

    has_many :project_members, foreign_key: :namespace_id, inverse_of: :namespace,
                               class_name: 'ProjectMember', dependent: :destroy
  end
end
