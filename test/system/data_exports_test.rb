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
    freeze_time
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      assert_selector 'tr:first-child td:first-child ', text: @data_export3.id
      assert_selector 'tr:first-child td:nth-child(2)', text: @data_export3.name
      assert_selector 'tr:first-child td:nth-child(3)', text: @data_export3.export_type.capitalize
      assert_selector 'tr:first-child td:nth-child(4)', text: @data_export3.status.capitalize
      assert find('tr:first-child td:nth-child(6)').text.blank?

      assert_selector 'tr:nth-child(2) td:first-child', text: @data_export4.id
      assert_selector 'tr:nth-child(2) td:nth-child(2)', text: @data_export4.name
      assert_selector 'tr:nth-child(2) td:nth-child(3)', text: @data_export4.export_type.capitalize
      assert_selector 'tr:nth-child(2) td:nth-child(4)', text: @data_export4.status.capitalize
      assert_selector 'tr:nth-child(2) td:nth-child(6)',
                      text: I18n.l(@data_export4.expires_at.localtime, format: :full_date)

      assert_selector 'tr:nth-child(3) td:first-child', text: @data_export5.id
      assert find('tr:nth-child(3) td:nth-child(2)').text.blank?
      assert_selector 'tr:nth-child(3) td:nth-child(3)', text: @data_export5.export_type.capitalize
      assert_selector 'tr:nth-child(3) td:nth-child(4)', text: @data_export5.status.capitalize
      assert_selector 'tr:nth-child(3) td:nth-child(6)',
                      text: I18n.l(@data_export5.expires_at.localtime, format: :full_date)
    end
  end

  test 'data exports with status ready will have download in action dropdown' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      within %(tr:first-child td:last-child) do
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_no_text I18n.t('data_exports.index.actions.download')
          assert_text I18n.t('data_exports.index.actions.delete')
        end
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

  test 'can view individual data export from data exports page' do
    freeze_time
    visit data_exports_path

    within %(#data-exports-table-body) do
      within %(tr:nth-child(2) td:first-child) do
        click_link @data_export4.id
      end

      assert_selector 'tr:first-child td:last-child', text: @data_export4.id
      assert_selector 'tr:nth-child(2) td:last-child', text: @data_export4.name
      assert_selector 'tr:nth-child(3) td:last-child', text: @data_export4.export_type.capitalize
      assert_selector 'tr:nth-child(4) td:last-child', text: @data_export4.status.capitalize
      assert_selector 'tr:nth-child(5) td:last-child',
                      text: I18n.l(@data_export4.created_at.localtime, format: :full_date)
      assert_selector 'tr:last-child td:last-child',
                      text: I18n.l(@data_export4.expires_at.localtime, format: :full_date)
    end
  end

  test 'name is blank on data export page if data_export.name is nil' do
    visit data_export_path(@data_export3)

    within %(#data-exports-table-body) do
      assert_no_text 'tr:nth-child(2) td:last-child'
    end
  end

  test 'expire is blank on data export page if data_export.status is processing' do
    visit data_export_path(@data_export3)

    within %(#data-exports-table-body) do
      assert_no_text 'tr:last-child td:last-child'
    end
  end

  test 'data export status pill colors' do
    visit data_export_path(@data_export3)

    within %(#data-exports-table-body) do
      within %(tr:nth-child(4) td:last-child) do
        assert_selector 'span.bg-gray-100.text-gray-800.text-xs.font-medium.rounded-full',
                        text: @data_export3.status.capitalize
      end
    end

    visit data_export_path(@data_export4)

    within %(#data-exports-table-body) do
      within %(tr:nth-child(4) td:last-child) do
        assert_selector 'span.bg-green-100.text-green-800.text-xs.font-medium.rounded-full',
                        text: @data_export4.status.capitalize
      end
    end
  end

  test 'disabled manifest tab and download button on exports that are processing' do
    visit data_export_path(@data_export3)

    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t(:'data_exports.show.download')
    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t(:'data_exports.show.tabs.manifest')
  end

  test 'can remove export from export page' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 3
      assert_text @data_export3.id
    end

    visit data_export_path(@data_export3)

    click_link I18n.t(:'data_exports.show.remove_button')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 2
      assert_no_text @data_export3.id
    end
  end
end
