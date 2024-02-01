# frozen_string_literal: true

class HistoryComponentPreview < ViewComponent::Preview
  # Default History Listing
  # ---------------------------
  #
  def default
    project_namespace = Project.first.namespace
    @log_data = project_namespace.log_data_without_changes

    render_with_template(locals: {

                           log_data: @log_data
                         })
  end
end
