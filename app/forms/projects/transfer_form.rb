# frozen_string_literal: true

module Projects
  # Form object for transferring projects
  class TransferForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :new_namespace_id, :string
    attribute :project

    validates :new_namespace_id, presence: true
    validate :new_namespace_exists, if: -> { new_namespace_id.present? }
    validate :project_does_not_conflict_with_new_namespace, if: -> { new_namespace_id.present? && project.present? }

    def initialize(attributes = {})
      super
    end

    def new_namespace
      Namespace.find_by(id: new_namespace_id)
    end

    private

    def new_namespace_exists
      return unless new_namespace.nil?

      errors.add(:new_namespace_id, :not_found)
    end

    def project_does_not_conflict_with_new_namespace
      if new_namespace_id.to_s == project.namespace.parent_id.to_s
        errors.add(:new_namespace_id, :cannot_be_same)
        return
      end

      return unless Namespaces::ProjectNamespace.where(parent_id: new_namespace_id)
                                                .exists?(['path = ? or name = ?', project.path, project.name])

      errors.add(:new_namespace_id, :project_exists)
    end
  end
end
