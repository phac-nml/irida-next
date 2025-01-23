# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Metadata Templates
    class MetadataTemplatesController < Projects::ApplicationController
      include MetadataTemplateActions

      private

      def metadata_template_params
        params.require(:metadata_template).permit
      end

      protected

      def namespace
        path = [params[:namespace_id], params[:project_id]].join('/')
        @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
        @namespace = @project.namespace
      end

      def metadata_templates_path
        namespace_project_samples_metadata_templates_path
      end
    end
  end
end
