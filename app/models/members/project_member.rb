# frozen_string_literal: true

# entity class for Member
class ProjectMember < Member
  belongs_to :project_namespace, foreign_key: :namespace_id, inverse_of: :namespace

  delegate :project, to: :project_namespace
end
