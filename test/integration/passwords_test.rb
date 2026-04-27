# frozen_string_literal: true

require 'test_helper'

class PasswordsViewTest < ActionView::TestCase
  test 'password reset form renders the error summary and inline field error for email errors' do
    user = User.new
    user.errors.add(:email, :blank)
    configure_devise_view_context(user)

    render template: 'devise/passwords/new'

    assert_select '[data-controller="form-error-summary"]'
    assert_select '#user_email_error', "Email can't be blank"
    assert_select 'a[href="#user_email"]', "Email can't be blank"
  end

  private

  def configure_devise_view_context(resource)
    view.singleton_class.class_eval do
      define_method(:resource) { resource }
      define_method(:resource_name) { :user }
      define_method(:resource_class) { User }
      define_method(:devise_mapping) { Devise.mappings[:user] }
      define_method(:controller_name) { 'passwords' }
      define_method(:params) { ActionController::Parameters.new }
    end
  end
end
