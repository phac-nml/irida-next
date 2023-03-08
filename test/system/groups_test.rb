# frozen_string_literal: true

require 'application_system_test_case'

class GroupsTest < ApplicationSystemTestCase
  def setup
    login_as users(:john_doe)
  end

  test 'can create a group' do
    Capybara.current_driver = :selenium
    visit groups_url

    click_button I18n.t(:'general.navbar.new_dropdown.aria_label')
    click_link I18n.t(:'general.navbar.new_dropdown.group')

    within %(div[data-controller="groups-new"]) do
      fill_in I18n.t(:'activerecord.attributes.group.name'), with: 'New group'
      fill_in 'Path', with: 'new-group' # <-- working but should happen dynamically
      fill_in 'Description', with: 'New group description'
      click_on I18n.t(:'groups.create.submit')
    end

    assert_text I18n.t(:'groups.create.success')
    assert_selector 'h1', text: 'New group'
  end
end
