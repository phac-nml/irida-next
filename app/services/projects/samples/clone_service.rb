# frozen_string_literal: true

module Projects
  module Samples
    # Service used to clone project samples
    class CloneService < BaseSampleCloneService
      private

      def clone_samples(sample_ids, broadcast_target) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        cloned_sample_ids = {}
        cloned_samples_data = []
        filtered_samples = filter_sample_ids(sample_ids, 'clone', Member::AccessLevel::MAINTAINER)

        total_sample_count = filtered_samples.count
        filtered_samples.each.with_index(1) do |sample, index|
          update_progress_bar(index, total_sample_count, broadcast_target)
          cloned_sample = clone_sample(sample)
          unless cloned_sample.nil?
            cloned_sample_ids[sample.id] = cloned_sample.id

            cloned_samples_data << { sample_name: sample.name, sample_puid: sample.puid,
                                     clone_puid: cloned_sample.puid }
          end
        end

        if cloned_sample_ids.count.positive?
          update_samples_count(cloned_sample_ids.count) if @new_project.parent.group_namespace?
          create_project_level_activity(cloned_samples_data, @namespace)
        end

        cloned_sample_ids
      end
    end
  end
end
