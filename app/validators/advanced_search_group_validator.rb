# frozen_string_literal: true

# Validator for advanced search group validator
class AdvancedSearchGroupValidator < AdvancedSearchGroupValidatorBase
  private

  def allowed_fields
    %w[name puid created_at updated_at attachments_updated_at]
  end

  def date_fields
    %w[created_at updated_at attachments_updated_at]
  end
end
