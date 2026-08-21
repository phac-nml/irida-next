# frozen_string_literal: true

class SearchComponentPreview < ViewComponent::Preview
  def default
    render_with_template(locals: {
                           url: Rails.application.routes.url_helpers.group_members_path(Group.first)
                         })
  end
end
