# frozen_string_literal: true

module Groups
  # Controller actions for Metadata Templates
  class MetadataTemplatesController < Groups::ApplicationController
    include MetadataTemplateActions

    before_action :current_page

    private

    def metadata_template_params
      defaults = { fields: [] }
      params.require(:metadata_template).permit(:name, :description, fields: []).reverse_merge(defaults)
    end

    protected

    def namespace
      @group ||= Group.find_by_full_path(request.params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      @namespace = @group
    end

    def context_crumbs
      super
      case action_name
      when 'index'
        @context_crumbs += [{
          name: t('groups.metadata_templates.index.title'),
          path: group_metadata_templates_path
        }]
      end
    end

    def current_page
      @current_page = t(:'groups.sidebar.metadata_templates')
    end

    def metadata_templates_path
      group_metadata_templates_path
    end
  end
end
