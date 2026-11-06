# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class AggregatedSamplesCountsServiceTest < ActiveSupport::TestCase
    test 'matches each group aggregated samples count' do
      groups = Group.all.to_a
      expected_counts = groups.to_h { |group| [group.id, group.aggregated_samples_count] }

      assert_equal expected_counts, AggregatedSamplesCountsService.new(groups:).execute
    end
  end
end
