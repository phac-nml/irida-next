# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Group Samples Spreadsheet Import Controller
    class SpreadsheetImportsController < Groups::ApplicationController
      include SampleSpreadsheetImportActions

      before_action :group_projects

      respond_to :turbo_stream

      private

      def namespace
        @namespace = group
      end

      def group
        @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      end

      def group_projects
        @group_projects = authorized_scope(Project, type: :relation, as: :group_projects,
                                                    scope_options: { group: @group })
      end

      def spreadsheet_import_params
        params.expect(spreadsheet_import: [:file, :sample_name_column, :project_puid_column, :sample_description_column,
                                           :static_project_id, { metadata_fields: [] }])
      end
    end
  end
end
