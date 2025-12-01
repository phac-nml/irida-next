# frozen_string_literal: true

module Groups
  module Samples
    # Service used to transfer samples from group level
    class TransferService < BaseSampleTransferService
      SampleExistsInProjectError = Class.new(StandardError)

      def create_group_activity(transferred_samples_data)
        group_activity_data = transferred_samples_data.values.flatten

        ext_details = ExtendedDetail.create!(details: { transferred_samples_count: group_activity_data.size,
                                                        transferred_samples_data: group_activity_data })

        activity = @namespace.create_activity key: 'group.samples.transfer',
                                              owner: current_user,
                                              parameters:
                                           {
                                             transferred_samples_count: group_activity_data.size,
                                             action: 'group_sample_transfer'
                                           }

        activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                 activity_type: 'group_sample_transfer')
      end

      def retrieve_sample_transfer_activity_data(old_project_id, new_project, sample_ids, transferred_samples_data)
        old_project = Project.find_by(id: old_project_id)
        transferred_samples_data[old_project_id] = Sample.where(id: sample_ids).pluck(:name, :puid).map do |name, puid|
          { sample_name: name, sample_puid: puid,
            source_project_name: old_project.name,
            source_project_id: old_project.id,
            source_project_puid: old_project.puid,
            target_project_name: new_project.name,
            target_project_id: new_project.id,
            target_project_puid: new_project.puid }
        end
      end
    end
  end
end
