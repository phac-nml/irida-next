# frozen_string_literal: true

require 'test_helper'

module Samples
  class CloneServiceTest < ActiveSupport::TestCase
    def setup
      @john_doe = users(:john_doe)
      @project = projects(:project1)
      @new_project = projects(:project2)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
    end

    test 'clone samples with permission' do
      @clone_samples_params = { new_project_id: @new_project.id,
                                sample_ids: [@sample1.id, @sample2.id] }
      cloned_sample_ids = Samples::CloneService.new(@project, @john_doe).execute(@clone_samples_params[:new_project_id],
                                                                                 @clone_samples_params[:sample_ids])
      cloned_sample_ids.each do |sample_id, clone_id|
        sample = Sample.find_by(id: sample_id)
        clone = Sample.find_by(id: clone_id)
        assert_equal @project.id, sample.project_id
        assert_equal @new_project.id, clone.project_id
        assert_equal sample.name, clone.name
        assert_equal sample.description,
                     clone.description
        assert_equal sample.metadata, clone.metadata
        # assert_equal sample.attachments, clone.attachments
      end
    end
  end
end
