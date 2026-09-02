# frozen_string_literal: true

require 'test_helper'

module MetadataTemplates
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @metadata_template = metadata_templates(:valid_metadata_template)
    end

    test 'updates metadata template with valid params' do
      valid_params = { name: 'new-metadata-template-name', description: 'new-metadata-template-description' }

      assert_changes -> { [@metadata_template.name, @metadata_template.description] },
                     to: %w[new-metadata-template-name new-metadata-template-description] do
        MetadataTemplates::UpdateService.new(@user, @metadata_template, valid_params).execute
      end
    end

    test 'fails to update metadata template with invalid params' do
      invalid_params = { fields: nil }

      assert_no_changes -> { @metadata_template.reload.fields } do
        MetadataTemplates::UpdateService.new(@user, @metadata_template, invalid_params).execute
      end
      assert_includes @metadata_template.errors[:fields],
                      I18n.t('activerecord.errors.models.metadata_template.attributes.fields.invalid',
                             error_type: 'array')
    end

    test 'fails to update metadata template with numerical fields' do
      invalid_params = { fields: [1] }

      assert_no_changes -> { @metadata_template.reload.fields } do
        MetadataTemplates::UpdateService.new(@user, @metadata_template, invalid_params).execute
      end
      assert_includes @metadata_template.errors[:fields],
                      I18n.t('activerecord.errors.models.metadata_template.attributes.fields.invalid',
                             error_type: 'string')
    end

    test 'fails to update metadata template with incorrect permissions' do
      valid_params = { name: 'new-metadata-template-name', description: 'new-metadata-template-description' }
      user = users(:david_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        MetadataTemplates::UpdateService.new(user, @metadata_template, valid_params).execute
      end

      assert_equal MetadataTemplatePolicy, exception.policy
      assert_equal :update_metadata_template?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'creates activity when metadata template is successfully updated' do
      namespace = @metadata_template.namespace
      valid_params = { name: 'new-metadata-template-name', description: 'new-metadata-template-description' }

      assert_difference -> { namespace.activities.count } do
        MetadataTemplates::UpdateService.new(@user, @metadata_template, valid_params).execute
      end

      activity = namespace.activities.where(key: 'namespaces_project_namespace.metadata_template.update').last
      assert_equal 'namespaces_project_namespace.metadata_template.update', activity.key
      assert_equal 'metadata_template_update', activity.parameters[:action]
      assert_equal @metadata_template.id, activity.parameters[:template_id]
      assert_equal 'new-metadata-template-name', activity.parameters[:template_name]
      assert_equal namespace.id, activity.parameters[:namespace_id]
    end

    test 'creates activity with group namespace key when update succeeds' do
      metadata_template = metadata_templates(:valid_group_metadata_template)
      namespace = metadata_template.namespace
      valid_params = { name: 'updated-group-template' }

      assert_difference -> { namespace.activities.count } do
        MetadataTemplates::UpdateService.new(@user, metadata_template, valid_params).execute
      end

      activity = namespace.activities.where(key: 'group.metadata_template.update').last
      assert_equal 'group.metadata_template.update', activity.key
      assert_equal 'metadata_template_update', activity.parameters[:action]
    end

    test 'does not create activity if metadata template update fails' do
      namespace = @metadata_template.namespace
      initial_activity_count = namespace.activities.count
      invalid_params = { fields: nil }

      MetadataTemplates::UpdateService.new(@user, @metadata_template, invalid_params).execute

      assert_equal initial_activity_count, namespace.activities.count
    end
  end
end
