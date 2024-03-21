# frozen_string_literal: true

require 'application_system_test_case'

class DataExportsTest < ApplicationSystemTestCase
  def setup
    @user = users(:jeff_doe)
    @data_export3 = data_exports(:data_export_three)
    @data_export4 = data_exports(:data_export_four)
    @data_export5 = data_exports(:data_export_five)
    login_as @user
  end

  test 'can view data exports' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      assert_selector 'tr:first-child td:first-child', text: @data_export3.name
      assert_selector 'tr:first-child td:nth-child(2)', text: @data_export3.export_type.capitalize
      assert_selector 'tr:first-child td:nth-child(3)', text: @data_export3.status.capitalize

      assert_selector 'tr:nth-child(2) td:first-child', text: @data_export4.name
      assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @data_export4.export_type.capitalize
      assert_selector 'tr:nth-child(2) td:nth-child(3)', text: @data_export4.status.capitalize

      assert_selector 'tr:nth-child(3) td:first-child', text: @data_export5.id
      assert_selector 'tr:nth-child(3) td:nth-child(2)', text: @data_export5.export_type.capitalize
      assert_selector 'tr:nth-child(3) td:nth-child(3)', text: @data_export5.status.capitalize
    end
  end

  test 'data exports with status ready have name within anchor tag and download in action dropdown' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      within %(tr:first-child td:first-child) do
        assert_text @data_export3.name
        assert_no_selector 'a'
      end

      within %(tr:first-child td:last-child) do
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_no_text I18n.t('data_exports.index.actions.download')
          assert_text I18n.t('data_exports.index.actions.delete')
        end
      end

      within %(tr:nth-child(3) td:first-child) do
        assert_text @data_export5.id
        assert_selector 'a', count: 1
      end

      within %(tr:nth-child(3) td:last-child) do
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_text I18n.t('data_exports.index.actions.download')
          assert_text I18n.t('data_exports.index.actions.delete')
        end
      end
    end
  end

  test 'can delete data exports' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      first('button.Viral-Dropdown--icon').click
      within('div[data-viral--dropdown-target="menu"] ul') do
        click_link I18n.t('data_exports.index.actions.delete'), match: :first
      end
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 2
      first('button.Viral-Dropdown--icon').click
      within('div[data-viral--dropdown-target="menu"] ul') do
        click_link I18n.t('data_exports.index.actions.delete'), match: :first
      end
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 1
      first('button.Viral-Dropdown--icon').click
      within('div[data-viral--dropdown-target="menu"] ul') do
        click_link I18n.t('data_exports.index.actions.delete'), match: :first
      end
    end
    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    assert_no_selector 'table'
    assert_text I18n.t('data_exports.index.no_data_exports')
    assert_text I18n.t('data_exports.index.no_data_exports_message')
  end
end
