# frozen_string_literal: true

# Base Entity Class
class ApplicationRecord < ActiveRecord::Base
  include PublicActivity::Common

  primary_abstract_class
  self.implicit_order_column = 'created_at'
end
