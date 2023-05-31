# frozen_string_literal: true

require 'test_helper'

module Samples
  class TransferServiceTest < ActiveSupport::TestCase
    def setup
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @project = projects(:project1)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample_transfer = SampleTransfer.new(project_id: @project.id,
                                            sample_ids: [JSON.generate([
                                                                         @sample1.id, @sample2.id
                                                                       ])])
    end

    test 'authorize allowed to transfer project samples with permission' do
      assert_authorized_to(:transfer?, @project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferService.new(@john_doe).execute(@sample_transfer)
      end
    end

    test 'transfer project samples without permission' do
      assert_raises(ActionPolicy::Unauthorized) do
        Samples::TransferService.new(@jane_doe).execute(@sample_transfer)
      end
    end

    test 'transfer project samples without specifying details' do
      assert_not Samples::TransferService.new(@john_doe).execute(nil)
    end
  end
end
