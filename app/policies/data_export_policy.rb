# frozen_string_literal: true

# Policy for data export authorization
class DataExportPolicy < ApplicationPolicy
  def destroy?
    true if record.user_id == user.id
  end

  def read_export?
    true if record.user_id == user.id
  end
end
