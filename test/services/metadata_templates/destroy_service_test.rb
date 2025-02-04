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
  end
end
