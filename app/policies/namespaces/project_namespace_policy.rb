# frozen_string_literal: true

# Policy for project namespace authorization
module Namespaces
  # Policy for authorization under project_namespace
  class ProjectNamespacePolicy < NamespacePolicy # rubocop:disable Metrics/ClassLength
    def effective_access_level
      @access_level ||= Member::AccessLevel::OWNER if record.parent&.user_namespace? && record.parent&.owner == user

      @access_level ||= @access_level = Member.effective_access_level(record, user)
      @access_level
    end

    def update?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def member_listing?
      if effective_access_level > Member::AccessLevel::NO_ACCESS &&
         effective_access_level != Member::AccessLevel::UPLOADER
        return true
      end

      details[:name] = record.name
      false
    end

    def create_member?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def destroy_member?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def update_member?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def link_namespace_with_group?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def unlink_namespace_with_group?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def update_namespace_with_group_link?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def create_bot_accounts?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def destroy_bot_accounts?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def view_bot_accounts?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def view_bot_personal_access_tokens?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def generate_bot_personal_access_token?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def revoke_bot_personal_access_token?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def create_automated_workflow_executions?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def destroy_automated_workflow_executions?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def update_automated_workflow_executions?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def view_automated_workflow_executions?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def submit_workflow?
      return true if effective_access_level >= Member::AccessLevel::ANALYST

      details[:name] = record.name
      false
    end

    def view_workflow_executions?
      return true if effective_access_level >= Member::AccessLevel::ANALYST

      details[:name] = record.name
      false
    end

    def export_data?
      return true if effective_access_level >= Member::AccessLevel::ANALYST

      details[:name] = record.name
      false
    end

    def update_sample_metadata?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def create_metadata_templates?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def destroy_metadata_templates?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end

    def update_metadata_templates?
      return true if Member::AccessLevel.manageable.include?(effective_access_level)

      details[:name] = record.name
      false
    end
  end
end
