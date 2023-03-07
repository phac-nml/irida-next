# frozen_string_literal: true

# entity class for Member
class ProjectMember < Member
  belongs_to :project_namespace, foreign_key: :namespace_id, class_name: 'Namespaces::ProjectNamespace' # rubocop:disable Rails/InverseOf

  delegate :project, to: :project_namespace
end
