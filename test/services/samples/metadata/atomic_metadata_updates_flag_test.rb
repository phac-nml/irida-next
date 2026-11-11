# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    # Verifies the atomic_metadata_updates flag only changes which implementation is used when
    # no 'metadata_update_implementation' param is explicitly passed, and never overrides an
    # explicit selector.
    class AtomicMetadataUpdatesFlagTest < ActiveSupport::TestCase
      def setup
        @user = users(:john_doe)
        @sample = samples(:sample33)
        @project = @sample.project
      end

      def teardown
        Flipper.enable(:atomic_metadata_updates)
      end

      test 'uses classified_atomic by default when the flag is enabled and no param is given' do
        Flipper.enable(:atomic_metadata_updates)

        service = UpdateService.new(@project, @sample, @user, { 'metadata' => { 'metadatafield1' => 'value1' } })

        assert_equal 'classified_atomic', service.send(:metadata_update_implementation)
      end

      test 'uses original by default when the flag is disabled' do
        Flipper.disable(:atomic_metadata_updates)

        service = UpdateService.new(@project, @sample, @user, { 'metadata' => { 'metadatafield1' => 'value1' } })

        assert_equal 'original', service.send(:metadata_update_implementation)
      end

      test 'an explicit implementation param always wins, regardless of the flag' do
        %w[original atomic cte_atomic classified_atomic].each do |implementation|
          [true, false].each do |flag_enabled|
            flag_enabled ? Flipper.enable(:atomic_metadata_updates) : Flipper.disable(:atomic_metadata_updates)

            service = UpdateService.new(@project, @sample, @user,
                                        { 'metadata' => { 'metadatafield1' => 'value1' },
                                          'metadata_update_implementation' => implementation })

            assert_equal implementation, service.send(:metadata_update_implementation)
          end
        end
      end
    end
  end
end
