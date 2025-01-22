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

    test 'updates metadata template with invalid params' do
      invalid_params = { fields: nil }

      assert_no_changes -> { [@metadata_template.fields] } do
        MetadataTemplates::UpdateService.new(@user, @metadata_template, invalid_params).execute
      end
    end

    test 'updates metadata template with incorrect permissions' do
      valid_params = { name: 'new-metadata-template-name', description: 'new-metadata-template-description' }
      user = users(:ryan_doe)

      exception = assert_raises(ActionPolicy::Unauthorized) do
        MetadataTemplates::UpdateService.new(user, @metadata_template, valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :update_metadata_template?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
    end
  end
end
