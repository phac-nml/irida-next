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

      assert_no_difference -> { MetadataTemplate.count } do
        MetadataTemplates::CreateService.new(@user, @namespace, invalid_params).execute
        assert @namespace.errors.full_messages.include?(I18n.t('services.metadata_templates.create.required.name'))
      end
    end
  end
end
