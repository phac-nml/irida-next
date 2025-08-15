# frozen_string_literal: true

class SearchComponentPreview < ViewComponent::Preview
  def default
    render_with_template(locals: {
                           url: group_members_url(Group.first)
                         })
  end
end
