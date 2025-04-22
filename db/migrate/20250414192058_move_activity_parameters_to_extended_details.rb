# frozen_string_literal: true

# Migration to move large activity parameters to extended details table and remove this data from activity parameters
class MoveActivityParametersToExtendedDetails < ActiveRecord::Migration[8.0] # rubocop:disable Metrics/ClassLength
  def change
    migrate_clone_data
    migrate_transfer_data
    migrate_multiple_destroy_data
  end

  # Migrates the cloned sample data from activities
  def migrate_clone_data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    activity_key = 'namespaces_project_namespace.samples.clone'

    activities = PublicActivity::Activity.where(key: activity_key)

    activities.each do |activity| # rubocop:disable Metrics/BlockLength
      activity_trackable = if activity.trackable.nil?
                             Namespace.with_deleted.find_by(id: activity.trackable_id)
                           else
                             activity.trackable
                           end
      cloned_samples_data = []

      existing_data = activity.parameters[:cloned_samples_puids]

      existing_data.each do |k, v|
        existing_puid = k.to_s
        new_puid = v.to_s

        sample = Sample.with_deleted.find_by(puid: existing_puid)

        cloned_samples_data << if sample
                                 { sample_name: sample.name, sample_puid: existing_puid, clone_puid: new_puid }
                               else
                                 { sample_name: 'deleted sample', sample_puid: existing_puid, clone_puid: new_puid }
                               end
      end

      activity_key_cloned_from = 'namespaces_project_namespace.samples.cloned_from'
      cloned_from_activities = PublicActivity::Activity.where(
        key: activity_key_cloned_from
      )

      activity_cloned_from = nil

      cloned_from_activities.each do |cloned_from_activity|
        if (cloned_from_activity.parameters[:source_project_puid] == activity_trackable.puid) &&
           (cloned_from_activity.parameters[:cloned_samples_puids] == existing_data)
          activity_cloned_from = cloned_from_activity
        end
      end

      ext_details = ExtendedDetail.create!(details: {
                                             cloned_samples_data: cloned_samples_data,
                                             cloned_samples_count: cloned_samples_data.size
                                           })

      if activity_trackable
        activity.parameters.delete(:cloned_samples_ids)
        activity.parameters.delete(:cloned_samples_puids)
        activity.parameters[:cloned_samples_count] = cloned_samples_data.size
        activity.save!
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id)
      end

      next unless !activity_cloned_from.nil? && Namespace.with_deleted.find_by(id: activity_cloned_from.trackable_id)

      activity_cloned_from.parameters.delete(:cloned_samples_ids)
      activity_cloned_from.parameters.delete(:cloned_samples_puids)
      activity_cloned_from.parameters[:cloned_samples_count] = cloned_samples_data.size
      activity_cloned_from.save!
      activity_cloned_from.create_activity_extended_detail(extended_detail_id: ext_details.id)
    end
  end

  # Migrates the transfer sample data from activities
  def migrate_transfer_data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    activity_key = 'namespaces_project_namespace.samples.transfer'

    activities = PublicActivity::Activity.where(key: activity_key)

    activities.each do |activity| # rubocop:disable Metrics/BlockLength
      activity_trackable = if activity.trackable.nil?
                             Namespace.with_deleted.find_by(id: activity.trackable_id)
                           else
                             activity.trackable
                           end

      existing_puids = activity.parameters[:transferred_samples_puids]
      transferred_samples_data = []

      existing_puids.each do |puid|
        sample = Sample.with_deleted.find_by(puid: puid)
        transferred_samples_data << if sample
                                      { sample_name: sample.name, sample_puid: sample.puid }
                                    else
                                      { sample_name: 'deleted sample', sample_puid: puid }
                                    end
      end

      activity_key_transferred_from = 'namespaces_project_namespace.samples.transferred_from'

      transferred_from_activities = PublicActivity::Activity.where(
        key: activity_key_transferred_from
      )

      activity_transferred_from = nil

      transferred_from_activities.each do |transferred_from_activity|
        if (transferred_from_activity.parameters[:source_project_puid] == activity_trackable.puid) &&
           (transferred_from_activity.parameters[:transferred_samples_puids] == existing_puids)
          activity_transferred_from = transferred_from_activity
        end
      end

      ext_details = ExtendedDetail.create!(details: {
                                             transferred_samples_data: transferred_samples_data,
                                             transferred_samples_count: transferred_samples_data.size
                                           })

      if activity_trackable
        activity.parameters.delete(:transferred_samples_ids)
        activity.parameters.delete(:transferred_samples_puids)
        activity.parameters[:transferred_samples_count] =
          transferred_samples_data.size
        activity.save!
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id)
      end

      unless !activity_transferred_from.nil? &&
             Namespace.with_deleted.find_by(id: activity_transferred_from.trackable_id)
        next
      end

      activity_transferred_from.parameters.delete(:transferred_samples_ids)
      activity_transferred_from.parameters.delete(:transferred_samples_puids)
      activity_transferred_from.parameters[:transferred_samples_count] = transferred_samples_data.size
      activity_transferred_from.save!
      activity_transferred_from.create_activity_extended_detail(extended_detail_id: ext_details.id)
    end
  end

  # Migrates the multiple destroy sample data from activities
  def migrate_multiple_destroy_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    activity_key = 'namespaces_project_namespace.samples.destroy_multiple'

    activities = PublicActivity::Activity.where(key: activity_key)

    activities.each do |activity|
      existing_puids = activity.parameters[:samples_deleted_puids]
      deleted_samples_data = []

      existing_puids.each do |puid|
        sample = Sample.with_deleted.find_by(puid: puid)
        deleted_samples_data << if sample
                                  { sample_name: sample.name, sample_puid: sample.puid }
                                else
                                  { sample_name: 'deleted sample', sample_puid: puid }
                                end
      end

      ext_details = ExtendedDetail.create!(details: {
                                             deleted_samples_data: deleted_samples_data,
                                             samples_deleted_count: deleted_samples_data.size
                                           })

      activity.parameters.delete(:samples_deleted_puids)
      activity.parameters.delete(:deleted_count)

      activity.parameters[:samples_deleted_count] = deleted_samples_data.size

      activity.save!
      activity.create_activity_extended_detail(extended_detail_id: ext_details.id)
    end
  end
end
