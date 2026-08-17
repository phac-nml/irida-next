# frozen_string_literal: true

module Projects
  module Samples
    # Service used to Delete Samples
    class DestroyService < BaseSampleDestroyService
      private

      def destroy_samples # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        samples = Sample.where(id: @sample_ids).where(project_id: @namespace.project.id)
        deleted_samples_data = []
        deleted_sample_ids = []
        samples = samples.destroy_all

        samples.each do |sample|
          next unless sample.deleted?

          update_metadata_summary(sample)
          deleted_sample_ids << sample.id
          deleted_samples_data << { sample_name: sample.name, sample_puid: sample.puid }
        end

        if deleted_sample_ids.any? && Flipper.enabled?(:sample_deletion_reason, current_user) &&
           params[:reason].present?
          Sample.only_deleted.where(id: deleted_sample_ids).update_all(deletion_reason: params[:reason]) # rubocop:disable Rails/SkipsModelValidations
        end

        deleted_samples_count = deleted_sample_ids.count
        create_project_activity(@namespace, deleted_samples_data) if deleted_samples_count.positive?
        deleted_samples_count
      end
    end
  end
end
