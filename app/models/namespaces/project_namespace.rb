# frozen_string_literal: true

module Namespaces
  # Namespace for Projects
  class ProjectNamespace < Namespace
    include History

    has_one :project, inverse_of: :namespace, foreign_key: :namespace_id, dependent: :destroy
    has_many :project_members, foreign_key: :namespace_id, inverse_of: :project_namespace,
                               class_name: 'Member', dependent: :destroy

    has_many :users, through: :project_members

    has_many :namespace_bots, foreign_key: :namespace_id, inverse_of: :namespace,
                              class_name: 'NamespaceBot', dependent: :destroy

    has_many :bots, through: :namespace_bots, source: :user

    has_many :shared_with_group_links, # rubocop:disable Rails/InverseOf
             lambda {
               where(namespace_type: Namespaces::ProjectNamespace.sti_name)
             },
             foreign_key: :namespace_id, class_name: 'NamespaceGroupLink',
             dependent: :destroy do
      def of_ancestors
        ns = proxy_association.owner

        NamespaceGroupLink.where(namespace_id: ns.parent.self_and_ancestor_ids)
      end

      def of_ancestors_and_self
        ns = proxy_association.owner

        source_ids = [ns.id] + ns.parent.self_and_ancestor_ids

        NamespaceGroupLink.where(namespace_id: source_ids)
      end
    end

    has_many :shared_with_groups, through: :shared_with_group_links, source: :group

    has_many :automated_workflow_executions, foreign_key: :namespace_id, inverse_of: :project_namespace,
                                             class_name: 'AutomatedWorkflowExecution', dependent: :destroy

    def self.sti_name
      'Project'
    end

    def update_metadata_summary_by_update_service(deleted_metadata, added_metadata)
      namespaces_to_update = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      subtract_from_metadata_summary_count(namespaces_to_update, deleted_metadata, true) unless deleted_metadata.empty?
      add_to_metadata_summary_count(namespaces_to_update, added_metadata, true) unless added_metadata.empty?
    end

    # self = the original parent of the transferred samples
    # new_project_id = the project ID receiving the new samples
    # transferred_samples_ids contains the IDs of the transferred samples
    def update_metadata_summary_by_sample_transfer(transferred_sample_id, old_namespaces, new_namespaces)
      sample = Sample.find(transferred_sample_id)
      return if sample.metadata.empty?

      subtract_from_metadata_summary_count(old_namespaces, sample.metadata, true)
      add_to_metadata_summary_count(new_namespaces, sample.metadata, true)
    end

    def update_metadata_summary_by_sample_deletion(sample)
      return if sample.metadata.empty?

      namespaces_to_update = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      subtract_from_metadata_summary_count(namespaces_to_update, sample.metadata, true)
    end

    def update_metadata_summary_by_sample_addition(sample)
      return if sample.metadata.empty?

      namespaces_to_update = [self] + parent.self_and_ancestors.where.not(type: Namespaces::UserNamespace.sti_name)
      add_to_metadata_summary_count(namespaces_to_update, sample.metadata, true)
    end

    def self.model_prefix
      'PRJ'
    end

    def automation_bot
      users.find_by(user_type: User.user_types[:project_automation_bot])
    end

    def retrieve_project_activity
      PublicActivity::Activity.where(
        trackable_id: id,
        trackable_type: 'Namespace'
      )
    end

    def broadcast_update(broadcast_target, current_index)
      Turbo::StreamsChannel.broadcast_action_to(
        broadcast_target,
        action: 'replace',
        target: 'progress-index',
        content: "<div id='progress-index' class='hidden' data-progress-bar-target='progressIndex'>#{current_index}</div>"
      )
    end
  end
end
