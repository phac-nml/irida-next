# frozen_string_literal: true

ActiveAdmin.register User do # rubocop:disable Metrics/BlockLength
  permit_params :email, :first_name, :last_name, :password, :password_confirmation

  scope :active, default: true do |scope|
    scope.where(deleted_at: nil)
  end

  scope :only_deleted

  scope :all, &:with_deleted

  scope :human, group: :user_type
  scope :project_bot, group: :user_type
  scope :group_bot, group: :user_type
  scope :project_automation_bot, group: :user_type

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :created_at
    actions
  end

  filter :email
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :first_name
      f.input :last_name
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
