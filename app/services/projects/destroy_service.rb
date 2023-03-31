# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    def execute
      # TODO: Remove the current_user == @project.namespace.owner once the project-members pr is merged in which
      # adds the creator as a project member
      if @project.namespace.project_members.find_by(user: current_user, access_level: Member::AccessLevel::OWNER) ||
         current_user == @project.namespace.owner
        @project.namespace.destroy
      else
        @project.errors.add(:base, 'You are not authorized to delete this project.')
      end
    end
  end
end
