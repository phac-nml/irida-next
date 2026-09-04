# frozen_string_literal: true

require 'test_helper'

module MetadataTemplates
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @metadata_template = metadata_templates(:valid_metadata_template)
    end

    test 'destroys metadata template with correct permissions' do
      assert_difference -> { MetadataTemplate.count } => -1 do
        MetadataTemplates::DestroyService.new(@user, @metadata_template).execute
      end

      assert_not MetadataTemplate.exists?(@metadata_template.id)
    end

    test 'fails to destroy metadata template with incorrect permissions' do
      user = users(:david_doe)

      assert_raises(ActionPolicy::Unauthorized) do
        MetadataTemplates::DestroyService.new(user, @metadata_template).execute
      end

      exception = assert_raises(ActionPolicy::Unauthorized) do
        MetadataTemplates::DestroyService.new(user, @metadata_template).execute
      end

      assert_equal MetadataTemplatePolicy, exception.policy
      assert_equal :destroy_metadata_template?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end

    test 'creates activity with group namespace key' do
      metadata_template = metadata_templates(:valid_group_metadata_template)
      namespace = metadata_template.namespace

      assert_difference -> { namespace.activities.count } do
        MetadataTemplates::DestroyService.new(@user, metadata_template).execute
      end

      activity = namespace.activities.where(key: 'group.metadata_template.destroy').last
      assert_equal 'group.metadata_template.destroy', activity.key
      assert_equal 'metadata_template_destroy', activity.parameters[:action]
      assert_equal metadata_template.id, activity.parameters[:template_id]
      assert_equal metadata_template.name, activity.parameters[:template_name]
      assert_equal namespace.id, activity.parameters[:namespace_id]
    end

    test 'creates activity with project namespace key' do
      namespace = @metadata_template.namespace

      assert_difference -> { namespace.activities.count } do
        MetadataTemplates::DestroyService.new(@user, @metadata_template).execute
      end

      activity = namespace.activities.where(key: 'namespaces_project_namespace.metadata_template.destroy').last
      assert_equal 'namespaces_project_namespace.metadata_template.destroy', activity.key
      assert_equal 'metadata_template_destroy', activity.parameters[:action]
      assert_equal @metadata_template.id, activity.parameters[:template_id]
      assert_equal @metadata_template.name, activity.parameters[:template_name]
      assert_equal namespace.id, activity.parameters[:namespace_id]
    end

    test 'does not create activity if metadata template is not deleted' do
      namespace = @metadata_template.namespace
      initial_activity_count = namespace.activities.count

      # Mock destroy to return false (not deleted)
      @metadata_template.define_singleton_method(:destroy) do
        false
      end
      @metadata_template.define_singleton_method(:deleted?) do
        false
      end

      MetadataTemplates::DestroyService.new(@user, @metadata_template).execute

      assert_equal initial_activity_count, namespace.activities.count
    end
  end
end
