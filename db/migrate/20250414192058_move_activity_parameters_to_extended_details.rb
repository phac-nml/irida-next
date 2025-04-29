# frozen_string_literal: true

# Migration to move large activity parameters to extended details table and remove this data from activity parameters
class MoveActivityParametersToExtendedDetails < ActiveRecord::Migration[8.0] # rubocop:disable Metrics/ClassLength
  def change
    # migrate_clone_data
    migrate_transfer_data
    migrate_multiple_destroy_data
  end

  # Migrates the cloned sample data from activities
  def migrate_clone_data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    activity_key = 'namespaces_project_namespace.samples.clone'

    activities = PublicActivity::Activity.where(key: activity_key)

    # Go through each of the activities for clone activities,
    # and copy the data from the activity parameters while transforming
    # to the correct format [{sample_name:, sample_puid:, clone_puid:},...]
    activities.each do |activity| # rubocop:disable Metrics/BlockLength
      activity_trackable = if activity.trackable.nil?
                             Namespace.with_deleted.find_by(id: activity.trackable_id)
                           else
                             activity.trackable
                           end
      cloned_samples_data = []

      existing_data = activity.parameters[:cloned_samples_puids]

      # Existing puid data was stored as {existing_puid:new_puid,....}
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

      next unless existing_data

      activity_key_cloned_from = 'namespaces_project_namespace.samples.cloned_from'
      cloned_from_activities = PublicActivity::Activity.where(
        key: activity_key_cloned_from
      ).where("parameters LIKE '%source_project_puid: #{activity_trackable.puid}%'")

      activity_cloned_from = nil

      # Get the `target project` activity which matches the source
      # project activity in the first activities loop
      cloned_from_activities.each do |cloned_from_activity|
        next if cloned_from_activity.parameters[:cloned_samples_puids].nil?
        next unless (cloned_from_activity.parameters[:source_project_puid] == activity_trackable.puid) &&
                    (cloned_from_activity.parameters[:cloned_samples_puids] == existing_data)

        activity_cloned_from = cloned_from_activity
      end

      # Create a shared extended_details table entry which will be
      # used by both the samples clone and cloned_from activities
      ext_details = ExtendedDetail.create!(details: {
                                             cloned_samples_data: cloned_samples_data,
                                             cloned_samples_count: cloned_samples_data.size
                                           })

      if activity_trackable
        # Remove existing cloned samples data stored in activity parameters
        activity.parameters.delete(:cloned_samples_ids)
        activity.parameters.delete(:cloned_samples_puids)

        # Add the count of cloned samples to the activity parameters
        activity.parameters[:cloned_samples_count] = cloned_samples_data.size

        activity.save!

        # Create the activity and extended details join table entry
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_clone')
      end

      next unless !activity_cloned_from.nil? && Namespace.with_deleted.find_by(id: activity_cloned_from.trackable_id)

      # Remove existing cloned samples data stored in cloned_from activity parameters
      activity_cloned_from.parameters.delete(:cloned_samples_ids)
      activity_cloned_from.parameters.delete(:cloned_samples_puids)

      # Add the count of cloned samples to the cloned_from activity parameters
      activity_cloned_from.parameters[:cloned_samples_count] = cloned_samples_data.size

      activity_cloned_from.save!

      # Create the activity and extended details join table entry
      activity_cloned_from.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                           activity_type: 'sample_clone')
    end
  end

  # Go through each of the activities for transfer activities,
  # and copy the data from the activity parameters while transforming
  # to the correct format [{sample_name:, sample_puid:},...]
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

      # Existing puid data was stored as [PUID1, PUID2,...]
      existing_puids.each do |puid|
        sample = Sample.with_deleted.find_by(puid: puid)
        transferred_samples_data << if sample
                                      { sample_name: sample.name, sample_puid: sample.puid }
                                    else
                                      { sample_name: 'deleted sample', sample_puid: puid }
                                    end
      end

      next unless existing_puids

      activity_key_transferred_from = 'namespaces_project_namespace.samples.transferred_from'

      transferred_from_activities = PublicActivity::Activity.where(
        key: activity_key_transferred_from
      ).where("parameters LIKE '%source_project_puid: #{activity_trackable.puid}%'")

      activity_transferred_from = nil

      # Get the `target project` activity which matches the source
      # project activity in the first activities loop
      transferred_from_activities.each do |transferred_from_activity|
        next if transferred_from_activity.parameters[:transferred_samples_puids].nil?
        next unless (transferred_from_activity.parameters[:source_project_puid] == activity_trackable.puid) &&
                    (transferred_from_activity.parameters[:transferred_samples_puids] - existing_puids).blank?

        activity_transferred_from = transferred_from_activity
      end

      # Create a shared extended_details table entry which will be
      # used by both the samples transfer and transferred_from activities
      ext_details = ExtendedDetail.create!(details: {
                                             transferred_samples_data: transferred_samples_data,
                                             transferred_samples_count: transferred_samples_data.size
                                           })

      if activity_trackable
        # Remove existing transferred samples data stored in activity parameters
        activity.parameters.delete(:transferred_samples_ids)
        activity.parameters.delete(:transferred_samples_puids)

        # Add the count of transferred samples to the activity parameters
        activity.parameters[:transferred_samples_count] =
          transferred_samples_data.size

        activity.save!

        # Create the activity and extended details join table entry
        activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_transfer')
      end

      unless !activity_transferred_from.nil? &&
             Namespace.with_deleted.find_by(id: activity_transferred_from.trackable_id)
        next
      end

      # Remove existing transferred samples data stored in transferred_from activity parameters
      activity_transferred_from.parameters.delete(:transferred_samples_ids)
      activity_transferred_from.parameters.delete(:transferred_samples_puids)

      # Add the count of transferred samples to the transferred_from activity parameters
      activity_transferred_from.parameters[:transferred_samples_count] = transferred_samples_data.size

      activity_transferred_from.save!

      # Create the activity and extended details join table entry
      activity_transferred_from.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                                                activity_type: 'sample_transfer')
    end
  end

  # Go through each of the activities for destroy_multiple activities,
  # and copy the data from the activity parameters while transforming
  # to the correct format [{sample_name:, sample_puid:},...]
  def migrate_multiple_destroy_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    activity_key = 'namespaces_project_namespace.samples.destroy_multiple'

    activities = PublicActivity::Activity.where(key: activity_key)

    activities.each do |activity|
      existing_puids = activity.parameters[:samples_deleted_puids]
      deleted_samples_data = []

      # Existing puid data was stored as [PUID1, PUID2,...]
      existing_puids.each do |puid|
        sample = Sample.with_deleted.find_by(puid: puid)
        deleted_samples_data << if sample
                                  { sample_name: sample.name, sample_puid: sample.puid }
                                else
                                  { sample_name: 'deleted sample', sample_puid: puid }
                                end
      end

      # Create a extended_details table entry
      ext_details = ExtendedDetail.create!(details: {
                                             deleted_samples_data: deleted_samples_data,
                                             samples_deleted_count: deleted_samples_data.size
                                           })

      # Remove existing destroyed samples data stored in activity parameters
      activity.parameters.delete(:samples_deleted_puids)
      activity.parameters.delete(:deleted_count)

      # Add the count of destroyed samples to the activity parameters
      activity.parameters[:samples_deleted_count] = deleted_samples_data.size

      activity.save!

      # Create the activity and extended details join table entry
      activity.create_activity_extended_detail(extended_detail_id: ext_details.id,
                                               activity_type: 'sample_destroy_multiple')
    end
  end
end
