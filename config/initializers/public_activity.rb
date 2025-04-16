# frozen_string_literal: true

PublicActivity::Activity.class_eval do
  has_one :activity_extended_detail
  has_one :extended_details, through: :activity_extended_detail, source: :extended_detail
end
