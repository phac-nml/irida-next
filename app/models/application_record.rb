# frozen_string_literal: true

# Base Entity Class
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def ransackable_attributes(_auth_object = nil)
    %w[id created_at updated_at]
  end

  def ransackable_associations(_auth_object = nil)
    %w[]
  end
end
