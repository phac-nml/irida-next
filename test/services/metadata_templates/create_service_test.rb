# frozen_string_literal: true

require 'test_helper'

module MetadataTemplates
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @namespace = @project.namespace
    end

    test 'creates a metadata template with valid parameters' do
      valid_params = {
        name: 'Sample Template',
        description: 'A test template',
        fields: ['Field 1', 'Field 2']
      }
      assert_difference -> { MetadataTemplate.count } => 1 do
        MetadataTemplates::CreateService.new(@user, @namespace, valid_params).execute
      end
    end

    test 'metadata template not created due to missing name' do
      invalid_params = {
        fields: ['Field 1', 'Field 2']
      }

      new_template = assert_no_difference -> { MetadataTemplate.count } do
        MetadataTemplates::CreateService.new(@user, @namespace, invalid_params).execute
      end

      assert new_template.errors.full_messages.include?(I18n.t('services.metadata_templates.create.required.name'))
    end

    test 'metadata template not created due to missing fields' do
      invalid_params = {
        name: 'Sample Template'
      }

      new_template = assert_no_difference -> { MetadataTemplate.count } do
        MetadataTemplates::CreateService.new(@user, @namespace, invalid_params).execute
      end

      assert new_template.errors.full_messages.include?(I18n.t('services.metadata_templates.create.required.fields'))
    end

    test 'raises unauthorized error when user lacks permission' do
      unauthorized_user = users(:jane_doe)
      valid_params = {
        name: 'Sample Template',
        fields: ['Field 1']
      }

      assert_raises(ActionPolicy::Unauthorized) do
        MetadataTemplates::CreateService.new(unauthorized_user, @namespace, valid_params).execute
      end
    end

    test 'creates activity record for group namespace' do
      group = groups(:group_one)
      valid_params = {
        name: 'Group Template',
        fields: ['Field 1']
      }

      template = assert_difference -> { PublicActivity::Activity.count } => 1 do
        MetadataTemplates::CreateService.new(@user, group, valid_params).execute
      end

      activity = PublicActivity::Activity.where(
        trackable_id: group.id, key: 'group.metadata_template.create'
      ).order(created_at: :desc).first
      assert_equal 'group.metadata_template.create', activity.key
      assert_equal @user, activity.owner
      assert_equal template.id, activity.parameters[:template_id]
      assert_equal 'Group Template', activity.parameters[:template_name]
      assert_equal group.id, activity.parameters[:namespace_id]
      assert_equal 'metadata_template_create', activity.parameters[:action]
    end

    test 'creates activity record for project namespace' do
      valid_params = {
        name: 'Project Template',
        fields: ['Field 1']
      }

      template = assert_difference -> { PublicActivity::Activity.count } => 1 do
        MetadataTemplates::CreateService.new(@user, @namespace, valid_params).execute
      end

      activity = PublicActivity::Activity.where(
        trackable_id: @namespace.id, key: 'namespaces_project_namespace.metadata_template.create'
      ).order(created_at: :desc).first
      assert_equal 'namespaces_project_namespace.metadata_template.create', activity.key
      assert_equal @user, activity.owner
      assert_equal template.id, activity.parameters[:template_id]
      assert_equal 'Project Template', activity.parameters[:template_name]
      assert_equal @namespace.id, activity.parameters[:namespace_id]
      assert_equal 'metadata_template_create', activity.parameters[:action]
    end

    test 'validates field format' do
      invalid_params = {
        name: 'Invalid Template',
        fields: 'not_an_array' # Should be an array
      }

      new_template = assert_no_difference -> { MetadataTemplate.count } do
        MetadataTemplates::CreateService.new(@user, @namespace, invalid_params).execute
      end

      assert new_template.errors.full_messages.include?(I18n.t('services.metadata_templates.create.required.fields'))
    end

    test 'prevents duplicate template names within same namespace' do
      # First template
      valid_params = {
        name: 'Duplicate Template',
        fields: ['Field 1']
      }

      MetadataTemplates::CreateService.new(@user, @namespace, valid_params).execute

      new_template = assert_no_difference -> { MetadataTemplate.count } do
        MetadataTemplates::CreateService.new(@user, @namespace, valid_params).execute
      end
      assert new_template.errors.full_messages.to_sentence.include?(
        I18n.t('activerecord.errors.messages.taken')
      )
    end
  end
end
