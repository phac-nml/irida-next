# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Group Samples Spreadsheet Import Controller
    class SpreadsheetImportsController < Groups::ApplicationController
      include SampleSpreadsheetImportActions

      before_action :ensure_enabled
      before_action :group_projects

      respond_to :turbo_stream

      private

      def namespace
        @namespace = group
      end

      def group
        @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      end

      def ensure_enabled
        not_found unless Flipper.enabled?(:batch_sample_spreadsheet_import)
      end

      def group_projects
        @group_projects_for_static_selection = []
        group_projects = authorized_scope(Project, type: :relation, as: :group_projects,
                                                   scope_options: { group: @group }).includes({ namespace: :route })
        group_projects.each do |project|
          @group_projects_for_static_selection << ["#{project.namespace.route.path} (#{project.namespace.puid})",
                                                   project.id]
        end
      end

      def spreadsheet_import_params
        params.expect(spreadsheet_import: %i[file sample_name_column project_puid_column sample_description_column
                                             static_project_id])
      end
    end
  end
end
