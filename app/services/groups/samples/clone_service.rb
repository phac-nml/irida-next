# frozen_string_literal: true

module Groups
  module Samples
    # Service used to clone samples
    class CloneService < BaseGroupService
      CloneError = Class.new(StandardError)

      def execute(new_project_id, sample_ids, broadcast_target = nil)
        authorize! @group, to: :clone_sample?
        validate(new_project_id, sample_ids)
        @new_project = Project.find_by(id: new_project_id)
        authorize! @new_project, to: :clone_sample_into_project?
        clone_samples(sample_ids, broadcast_target)
      rescue Groups::Samples::CloneService::CloneError => e
        @group.errors.add(:base, e.message)
        {}
      end

      private

      def validate(new_project_id, sample_ids)
        raise CloneError, I18n.t('services.samples.clone.empty_new_project_id') if new_project_id.blank?

        raise CloneError, I18n.t('services.samples.clone.empty_sample_ids') if sample_ids.blank?
      end

      def clone_samples(sample_ids, broadcast_target) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        puts 'hihihihiihi4'
        cloned_sample_ids = {}
        cloned_samples_data = []

        not_found_sample_ids = []
        total_sample_count = sample_ids.count
        sample_ids.each.with_index(1) do |sample_id, index|
          update_progress_bar(index, total_sample_count, broadcast_target)
          sample = Sample.find(sample_id)
          cloned_sample = clone_sample(sample)
          cloned_sample_ids[sample_id] = cloned_sample.id unless cloned_sample.nil?

          unless cloned_sample.nil?
            cloned_samples_data << { sample_name: sample.name, sample_puid: sample.puid,
                                     clone_puid: cloned_sample.puid }
          end
        rescue ActiveRecord::RecordNotFound
          not_found_sample_ids << sample_id
          next
        end

        unless not_found_sample_ids.empty?
          @group.errors.add(:samples,
                            I18n.t('services.samples.clone.samples_not_found',
                                   sample_ids: not_found_sample_ids.join(', ')))
        end

        if cloned_sample_ids.count.positive?
          update_namespace_attributes(cloned_sample_ids)
          create_activities(cloned_samples_data, cloned_sample_ids.count)
        end

        cloned_sample_ids
      end

      def clone_sample(sample)
        clone = sample.dup
        clone.project_id = @new_project.id
        clone.generate_puid
        clone.save!

        # update new project metadata summary and then clone attachments to the sample
        @new_project.namespace.update_metadata_summary_by_sample_addition(sample)
        clone_attachments(sample, clone)

        clone
      rescue ActiveRecord::RecordInvalid
        @group.errors.add(:samples, I18n.t('services.samples.clone.sample_exists', sample_name: sample.name,
                                                                                   sample_puid: sample.puid))
        nil
      end

      def clone_attachments(sample, clone)
        files = sample.attachments.map { |attachment| attachment.file.blob }
        ::Attachments::CreateService.new(current_user, clone, { files:, include_activity: false }).execute
      end

      def update_samples_count(cloned_samples_count)
        @new_project.parent.update_samples_count_by_addition_services(cloned_samples_count)
      end

      def update_namespace_attributes(cloned_sample_ids)
        update_samples_count(cloned_sample_ids.count) if @new_project.parent.type == 'Group'
      end

      def create_activities(cloned_samples_data, cloned_samples_count)
        # ext_details = ExtendedDetail.create!(details: { cloned_samples_count: cloned_samples_count,
        #                                                 cloned_samples_data: cloned_samples_data })

        # activity = @project.namespace.create_activity key: 'namespaces_project_namespace.samples.clone',
        #                                               owner: current_user,
        #                                               parameters:
        #                                               {
        #                                                 target_project_puid: @new_project.puid,
        #                                                 target_project: @new_project.id,
        #                                                 cloned_samples_count: cloned_samples_count,
        #                                                 action: 'sample_clone'
        #                                               }

        # activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_clone')

        # activity = @new_project.namespace.create_activity key: 'namespaces_project_namespace.samples.cloned_from',
        #                                                   owner: current_user,
        #                                                   parameters:
        #                                                   {
        #                                                     source_project_puid: @project.puid,
        #                                                     source_project: @project.id,
        #                                                     cloned_samples_count: cloned_samples_count,
        #                                                     action: 'sample_clone'
        #                                                   }

        # activity.create_activity_extended_detail(extended_detail_id: ext_details.id, activity_type: 'sample_clone')
      end
    end
  end
end
