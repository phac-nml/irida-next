# frozen_string_literal: true

module Members
  # entity class for Member
  class ProjectMember < Member
    belongs_to :project_namespace, foreign_key: :namespace_id, class_name: 'Namespaces::ProjectNamespace' # rubocop:disable Rails/InverseOf

    delegate :project, to: :project_namespace

    def self.sti_name
      'ProjectMember'
    end
  end
end
