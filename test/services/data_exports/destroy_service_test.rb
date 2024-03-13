# frozen_string_literal: true

require 'test_helper'

module DataExports
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @data_export = data_exports(:data_export_one)
    end

    test 'destroy data export with valid permission' do
      assert_difference -> { DataExport.count } => -1 do
        DataExports::DestroyService.new(@data_export, @user).execute
      end
    end

    test 'destroy data export including attachment with valid permission' do
      @data_export.file.attach(io: Rails.root.join('test/fixtures/files/data_export_1.zip').open,
                               filename: 'data_export_1.zip')
      assert_equal 'data_export_1.zip', @data_export.file.filename.to_s

      assert_difference -> { DataExport.count } => -1 do
        assert_difference -> { ActiveStorage::Attachment.count } => -1 do
          DataExports::DestroyService.new(@data_export, @user).execute
        end
      end
    end

    test 'unable to destroy data export due to invalid permission' do
      user = users(:steve_doe)

      assert_raises(ActionPolicy::Unauthorized) { DataExports::DestroyService.new(@data_export, user).execute }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        DataExports::DestroyService.new(@data_export, user).execute
      end

      assert_equal DataExportPolicy, exception.policy
      assert_equal :destroy?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.data_export.destroy?'),
                   exception.result.message
    end
  end
end
