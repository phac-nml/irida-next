# frozen_string_literal: true

require 'test_helper'

module Samples
  module Metadata
    class CteAtomicUpdateServiceTest < ActiveSupport::TestCase
      def test_matches_atomic_update_service_for_all_metadata_change_states
        freeze_time
        cte_sample = samples(:sample32)
        atomic_sample = samples(:sample33)
        metadata = {
          'metadatafield1' => 'updated value',
          'metadatafield2' => '',
          'metadatafield3' => 'created value'
        }

        atomic_changes = AtomicUpdateService.new(atomic_sample, 10, metadata).execute
        cte_changes = CteAtomicUpdateService.new(cte_sample, 10, metadata).execute

        assert_equal atomic_changes, cte_changes

        atomic_sample.reload
        cte_sample.reload
        assert_equal atomic_sample.metadata, cte_sample.metadata
        assert_equal atomic_sample.metadata_provenance, cte_sample.metadata_provenance
      end
    end
  end
end
