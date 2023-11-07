# frozen_string_literal: true

# Base Entity Class
class ApplicationRecord < ActiveRecord::Base
  include PublicActivity::Model
  tracked owner: proc { |controller, _model| controller.current_user }

  primary_abstract_class
  self.implicit_order_column = 'created_at'
end
