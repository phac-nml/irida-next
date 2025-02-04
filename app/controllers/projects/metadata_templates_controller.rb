# frozen_string_literal: true

module Projects
  # Controller actions for Metadata Templates
  class MetadataTemplatesController < Projects::ApplicationController
    include MetadataTemplateActions

    before_action :current_page

    private

    def metadata_template_params
      params.require(:metadata_template).permit(:name, fields: [])
    end

    protected

    def namespace
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      @namespace = @project.namespace
    end

    def metadata_templates_path
      namespace_project_metadata_templates_path
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: t('projects.metadata_templates.index.title'),
          path: namespace_project_metadata_templates_path
        }]
      end
    end

    def current_page
      @current_page = t(:'projects.sidebar.metadata_templates')
    end
  end
end
