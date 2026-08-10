# frozen_string_literal: true

module Projects
  module Samples
    # Service used to Delete Samples
    class DestroyService < BaseSampleDestroyService
      private

      def destroy_samples # rubocop:disable Metrics/AbcSize
        samples = Sample.where(id: @sample_ids).where(project_id: @namespace.project.id)
        samples_deleted_puids = []
        deleted_samples_data = []
        samples = samples.destroy_all

        samples.each do |sample|
          next unless sample.deleted?

          sample.update_column(:deletion_reason, params[:reason]) # rubocop:disable Rails/SkipsModelValidations
          update_metadata_summary(sample)
          samples_deleted_puids << sample.puid
          deleted_samples_data << { sample_name: sample.name, sample_puid: sample.puid }
        end

        deleted_samples_count = samples_deleted_puids.count
        create_project_activity(@namespace, deleted_samples_data) if deleted_samples_count.positive?
        deleted_samples_count
      end
    end
  end
end
