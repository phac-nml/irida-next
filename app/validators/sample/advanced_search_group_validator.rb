# frozen_string_literal: true

# Validator for advanced search groups in Sample queries.
class Sample::AdvancedSearchGroupValidator < AdvancedSearch::GroupValidator # rubocop:disable Style/ClassAndModuleChildren
  private

  def allowed_fields
    %w[name puid created_at updated_at attachments_updated_at]
  end

  def date_fields
    %w[created_at updated_at attachments_updated_at]
  end
end
