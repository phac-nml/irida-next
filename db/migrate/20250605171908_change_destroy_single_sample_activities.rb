# frozen_string_literal: true

# migrate project 'single_destroy' sample activity to use destroy_multiple
class ChangeDestroySingleSampleActivities < ActiveRecord::Migration[8.0]
  def change
    activities = PublicActivity::Activity.where(key: 'namespaces_project_namespace.samples.destroy')

    activities.each do |activity|
      sample = Sample.with_deleted.find_by(puid: sample_puid)
      sample_puid = activity.parameters[:sample_puid]
      sample_name = sample.nil? ? 'deleted_sample' : sample.name

      ext_details = ExtendedDetail.create!(details: { samples_deleted_count: 1,
                                                      deleted_samples_data: [{ sample_name:, sample_puid: }] })
      activity.key = 'namespaces_project_namespace.samples.destroy_multiple'

      activity.parameters = { samples_deleted_count: 1,
                              action: 'sample_destroy_multiple' }

      activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                               activity_type: 'sample_destroy_multiple')
      activity.save
    end
  end
end
