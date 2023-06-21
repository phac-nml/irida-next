# frozen_string_literal: true

require 'test_helper'

module Samples
  class TransferServiceTest < ActiveSupport::TestCase
    def setup
      @john_doe = users(:john_doe)
      @jane_doe = users(:jane_doe)
      @current_project = projects(:project1)
      @new_project = projects(:project2)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
    end

    test 'transfer project samples with permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [JSON.generate([
                                                               @sample1.id, @sample2.id
                                                             ])] }

      assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
        Samples::TransferService.new(@current_project, @john_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
      end
    end

    test 'transfer project samples without specifying details' do
      assert_not Samples::TransferService.new(@current_project, @john_doe).execute(nil, nil)
    end

    test 'transfer project samples to existing project' do
      @sample_transfer_params = { new_project_id: @current_project.id,
                                  sample_ids: [JSON.generate([
                                                               @sample1.id, @sample2.id
                                                             ])] }

      assert_not Samples::TransferService.new(@current_project, @john_doe)
                                         .execute(@sample_transfer_params[:new_project_id],
                                                  @sample_transfer_params[:sample_ids])
    end

    test 'authorize allowed to transfer project samples with project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [JSON.generate([
                                                               @sample1.id, @sample2.id
                                                             ])] }

      assert_authorized_to(:transfer_sample?, @current_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferService.new(@current_project, @john_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
      end
    end

    test 'authorize allowed to transfer project samples with target project permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [JSON.generate([
                                                               @sample1.id, @sample2.id
                                                             ])] }

      assert_authorized_to(:transfer_sample_into_project?, @new_project,
                           with: ProjectPolicy,
                           context: { user: @john_doe }) do
        Samples::TransferService.new(@current_project, @john_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
      end
    end

    test 'transfer project samples without permission' do
      @sample_transfer_params = { new_project_id: @new_project.id,
                                  sample_ids: [JSON.generate([
                                                               @sample1.id, @sample2.id
                                                             ])] }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        Samples::TransferService.new(@current_project, @jane_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
      end

      assert_equal ProjectPolicy, exception.policy
      assert_equal :transfer_sample?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.project.transfer_sample?',
                          name: @current_project.name),
                   exception.result.message
    end
  end
end
