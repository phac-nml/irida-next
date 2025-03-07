# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Group Samples File Import Controller
    class FileImportsController < Groups::ApplicationController
      include SampleFileImportActions

      respond_to :turbo_stream

      private

      def namespace
        @namespace = group
      end

      def group
        @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      end
    end
  end
end
