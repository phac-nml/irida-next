# frozen_string_literal: true

# Migration to move large activity parameters to extended details table
class MoveActivityParametersToExtendedDetails < ActiveRecord::Migration[8.0] # rubocop:disable Metrics/ClassLength
  def change
    migrate_clone_data
    migrate_transfer_data
    migrate_multiple_destroy_data
  end

  def migrate_clone_data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    activity_key = 'namespaces_project_namespace.samples.clone'

    activities = PublicActivity::Activity.where(key: activity_key)

    activities.each do |activity| # rubocop:disable Metrics/BlockLength
      activity_trackable = activity.trackable
      cloned_samples_data = []

      existing_data = activity.parameters[:cloned_samples_puids]

      existing_data.each do |k, v|
        existing_puid = k.to_s
        new_puid = v.to_s

        sample = Sample.with_deleted.find_by(puid: existing_puid)

        cloned_samples_data << if sample
                                 [sample.name, existing_puid, new_puid]
                               else
                                 ['deleted sample', existing_puid, new_puid]
                               end
      end

      activity_key_cloned_from = 'namespaces_project_namespace.samples.cloned_from'
      activity_cloned_from = PublicActivity::Activity.where(
        key: activity_key_cloned_from,
        parameters: { source_project_puid: activity_trackable.puid }
      )

      ext_details = ExtendedDetail.create!(details: {
                                             cloned_samples_data: cloned_samples_data,
                                             cloned_samples_count: cloned_samples_data.size
                                           })

      if Namespace.with_deleted.find_by(id: activity_trackable.id)
        activity.parameters.delete(:cloned_samples_ids)
        activity.parameters.delete(:cloned_samples_puids)
        activity[:extended_details_id] = ext_details.id
        activity.parameters[:cloned_samples_count] = cloned_samples_data.size
        activity.save!
      end

      next unless Namespace.with_deleted.find_by(id: activity_cloned_from.trackable_id)

      activity_cloned_from.parameters.delete(:cloned_samples_ids)
      activity_cloned_from.parameters.delete(:cloned_samples_puids)
      activity_cloned_from[:extended_details_id] = ext_details.id
      activity_cloned_from[:cloned_samples_count] = cloned_samples_data.size
      activity_cloned_from.save!
    end
  end

  def migrate_transfer_data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    activity_key = 'namespaces_project_namespace.samples.transfer'

    activities = PublicActivity::Activity.where(key: activity_key)

    activities.each do |activity| # rubocop:disable Metrics/BlockLength
      activity_trackable = activity.trackable
      existing_puids = activity.parameters[:transferred_samples_puids]
      transferred_samples_data = []

      existing_puids.each do |puid|
        sample = Sample.with_deleted.find_by(puid: puid)
        transferred_samples_data << if sample
                                      [sample.name, sample.puid]
                                    else
                                      ['deleted sample', 'deleted sample']
                                    end
      end

      activity_key_transferred_from = 'namespaces_project_namespace.samples.transferred_from'
      activity_transferred_from = PublicActivity::Activity.where(
        key: activity_key_transferred_from,
        parameters: { source_project_puid: activity_trackable.puid }
      )

      ext_details = ExtendedDetail.create!(details: {
                                             transferred_samples_data: transferred_samples_data,
                                             transferred_samples_count: transferred_samples_data.size
                                           })

      if Namespace.with_deleted.find_by(id: activity_trackable.id)
        activity.parameters.delete(:transferred_samples_ids)
        activity.parameters.delete(:transferred_samples_puids)
        activity[:extended_details_id] = ext_details.id
        activity.parameters[:transferred_samples_count] =
          transferred_samples_data.size
        activity.save!
      end

      next unless Namespace.with_deleted.find_by(id: activity_transferred_from.trackable_id)

      activity_transferred_from.parameters.delete(:transferred_samples_ids)
      activity_transferred_from.parameters.delete(:transferred_samples_puids)
      activity_transferred_from[:extended_details_id] = ext_details.id
      activity_transferred_from[:transferred_samples_count] = transferred_samples_data.size
      activity_transferred_from.save!
    end
  end

  def migrate_multiple_destroy_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    activity_key = 'namespaces_project_namespace.samples.destroy_multiple'

    activities = PublicActivity::Activity.where(key: activity_key)

    activities.each do |activity|
      existing_puids = activity.parameters[:samples_deleted_puids]
      deleted_samples_data = []

      existing_puids.each do |puid|
        sample = Sample.with_deleted.find_by(puid: puid)
        deleted_samples_data << if sample
                                  [sample.name, sample.puid]
                                else
                                  ['deleted sample', 'deleted sample']
                                end
      end

      ext_details = ExtendedDetail.create!(details: {
                                             deleted_samples_data: deleted_samples_data,
                                             samples_deleted_count: deleted_samples_data.size
                                           })

      activity.parameters.delete(:samples_deleted_puids)
      activity.parameters.delete(:deleted_count)

      activity[:extended_details_id] = ext_details.id
      activity.parameters[:samples_deleted_count] = deleted_samples_data.size

      activity.save!
    end
  end
end
