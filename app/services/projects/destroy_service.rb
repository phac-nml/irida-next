# frozen_string_literal: true

module Projects
  # Service used to Delete Projects
  class DestroyService < BaseProjectService
    def execute
      if @project.namespace.owners.include?(current_user)
        @project.namespace.destroy
      else
        @project.errors.add(:base, 'You are not authorized to delete this project.')
      end
    end
  end
end
