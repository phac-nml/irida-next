# frozen_string_literal: true

require 'application_system_test_case'

module Admin
  class AccessibilityTest < ApplicationSystemTestCase
    setup do
      login_as users(:system_user)
    end

    test 'admin layout is accessible' do
      page.visit admin_root_path

      assert_selector 'nav[data-controller="active-admin-navigation"]:not([inert])', visible: :all
      assert_no_selector '#main-menu[aria-hidden]', visible: :all
      assert_accessible
    end
  end
end
