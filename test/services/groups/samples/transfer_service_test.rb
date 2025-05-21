# frozen_string_literal: true

require 'test_helper'

module Groups
  module Samples
    class TransferServiceTest < ActiveSupport::TestCase
      def setup
        @john_doe = users(:john_doe)
        @jane_doe = users(:jane_doe)
        @joan_doe = users(:joan_doe)
        @ryan_doe = users(:ryan_doe)
        @group = groups(:group_one)
        @current_project = projects(:project1)
        @new_project = projects(:project2)
        @sample1 = samples(:sample1)
        @sample2 = samples(:sample2)
      end

      test 'transfer group samples with permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
          Groups::Samples::TransferService.new(@group, @john_doe).execute(
            @sample_transfer_params[:new_project_id],
            @sample_transfer_params[:sample_ids]
          )
        end
      end

      test 'transfer group samples with maintainer permission within hierarchy' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_changes -> { @sample1.reload.project.id }, to: @new_project.id do
          Groups::Samples::TransferService.new(@group, @joan_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
        end
      end

      test 'transfer group samples with maintainer permission but outside of hierarchy' do
        new_project = projects(:project32)

        @sample_transfer_params = { new_project_id: new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_no_changes -> { @sample1.reload.project.id } do
          Groups::Samples::TransferService.new(@group, @joan_doe).execute(
            @sample_transfer_params[:new_project_id],
            @sample_transfer_params[:sample_ids]
          )
        end

        assert @group.errors.full_messages.include?(
          I18n.t('services.groups.samples.transfer.maintainer_transfer_not_allowed')
        )
      end

      test 'transfer group samples without specifying details' do
        assert_empty Groups::Samples::TransferService.new(@group, @john_doe).execute(nil, nil)
      end

      test 'transfer group samples to existing project' do
        @sample_transfer_params = { new_project_id: @current_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_empty Groups::Samples::TransferService.new(@group, @john_doe)
                                                     .execute(@sample_transfer_params[:new_project_id],
                                                              @sample_transfer_params[:sample_ids])
      end

      test 'authorize allowed to transfer group samples with project permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_authorized_to(:transfer_sample?, @group,
                             with: GroupPolicy,
                             context: { user: @john_doe }) do
          Groups::Samples::TransferService.new(@group, @john_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
        end
      end

      test 'authorize allowed to transfer group samples with target project permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        assert_authorized_to(:transfer_sample_into_project?, @new_project,
                             with: ProjectPolicy,
                             context: { user: @john_doe }) do
          Groups::Samples::TransferService.new(@group, @john_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
        end
      end

      test 'transfer group samples without permission' do
        @sample_transfer_params = { new_project_id: @new_project.id,
                                    sample_ids: [@sample1.id, @sample2.id] }

        exception = assert_raises(ActionPolicy::Unauthorized) do
          Groups::Samples::TransferService.new(@group, @ryan_doe).execute(@sample_transfer_params[:new_project_id],
                                                                          @sample_transfer_params[:sample_ids])
        end

        assert_equal GroupPolicy, exception.policy
        assert_equal :transfer_sample?, exception.rule
        assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
        assert_equal I18n.t(:'action_policy.policy.group.transfer_sample?',
                            name: @group.name),
                     exception.result.message
      end
    end
  end
end
