# frozen_string_literal: true

require 'application_system_test_case'

class DataExportsTest < ApplicationSystemTestCase
  def setup
    @user = users(:john_doe)
    @data_export1 = data_exports(:data_export_one)
    @data_export2 = data_exports(:data_export_two)
    login_as @user
  end

  test 'can view data exports' do
    freeze_time
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 2
      assert_selector 'tr:first-child td:first-child ', text: @data_export1.id
      assert_selector 'tr:first-child td:nth-child(2)', text: @data_export1.name
      assert_selector 'tr:first-child td:nth-child(3)', text: @data_export1.export_type.capitalize
      assert_selector 'tr:first-child td:nth-child(4)', text: @data_export1.status.capitalize
      assert_selector 'tr:first-child td:nth-child(6)',
                      text: I18n.l(@data_export1.expires_at.localtime, format: :full_date)

      assert_selector 'tr:nth-child(2) td:first-child', text: @data_export2.id
      assert find('tr:nth-child(2) td:nth-child(2)').text.blank?
      assert_selector 'tr:nth-child(2) td:nth-child(3)', text: @data_export2.export_type.capitalize
      assert_selector 'tr:nth-child(2) td:nth-child(4)', text: @data_export2.status.capitalize
      assert find('tr:nth-child(2) td:nth-child(6)').text.blank?
    end
  end

  test 'data exports with status ready will have download in action dropdown' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      within %(tr:nth-child(2) td:last-child) do
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_no_text I18n.t('data_exports.index.actions.download')
          assert_text I18n.t('data_exports.index.actions.delete')
        end
      end

      within %(tr:first-child td:last-child) do
        first('button.Viral-Dropdown--icon').click
        within('div[data-viral--dropdown-target="menu"] ul') do
          assert_text I18n.t('data_exports.index.actions.download')
          assert_text I18n.t('data_exports.index.actions.delete')
        end
      end
    end
  end

  test 'can delete data exports on listing page' do
    visit data_exports_path

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

  test 'can navigate to individual data export page from data exports page' do
    freeze_time
    visit data_exports_path

    within %(#data-exports-table-body) do
      within %(tr:first-child td:first-child) do
        click_link @data_export1.id
      end
    end

    within %(#data-export-listing) do
      assert_selector 'div:first-child dd', text: @data_export1.id
      assert_selector 'div:nth-child(2) dd', text: @data_export1.name
      assert_selector 'div:nth-child(3) dd', text: @data_export1.export_type.capitalize
      assert_selector 'div:nth-child(4) dd', text: @data_export1.status.capitalize
      assert_selector 'div:nth-child(5) dd',
                      text: I18n.l(@data_export1.created_at.localtime, format: :full_date)
      assert_selector 'div:last-child dd',
                      text: I18n.l(@data_export1.expires_at.localtime, format: :full_date)
    end
  end

  test 'name is not shown on data export page if data_export.name is nil' do
    visit data_export_path(@data_export2)

    within %(#data-export-listing) do
      assert_no_text I18n.t('data_exports.summary.name')
    end
  end

  test 'expire has once_ready text on data export page if data_export.status is processing' do
    visit data_export_path(@data_export2)

    within %(#data-export-listing) do
      assert_selector 'div:last-child dd',
                      text: I18n.t('data_exports.summary.once_ready')
    end
  end

  test 'data export status pill colors' do
    # processing
    visit data_export_path(@data_export2)

    within %(#data-export-listing) do
      within %(div:nth-child(3) dd) do
        assert_selector 'span.bg-gray-100.text-gray-800.text-xs.font-medium.rounded-full',
                        text: @data_export2.status.capitalize
      end
    end

    # ready
    visit data_export_path(@data_export1)

    within %(#data-export-listing) do
      within %(div:nth-child(4) dd) do
        assert_selector 'span.bg-green-100.text-green-800.text-xs.font-medium.rounded-full',
                        text: @data_export1.status.capitalize
      end
    end
  end

  test 'hidden manifest tab and download btn when status is processing' do
    visit data_export_path(@data_export1)

    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t(:'data_exports.show.download')
    assert_no_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                       text: I18n.t(:'data_exports.show.tabs.manifest')

    visit data_export_path(@data_export2)

    assert_selector 'a.pointer-events-none.cursor-not-allowed.bg-slate-100.text-slate-600',
                    text: I18n.t(:'data_exports.show.download')
    assert_no_text I18n.t(:'data_exports.show.tabs.manifest')
  end

  test 'can remove export from export page' do
    visit data_exports_path

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 2
      assert_text @data_export2.id
    end

    visit data_export_path(@data_export2)

    click_link I18n.t(:'data_exports.show.remove_button')

    within('#turbo-confirm[open]') do
      click_button I18n.t(:'components.confirmation.confirm')
    end

    within %(#data-exports-table-body) do
      assert_selector 'tr', count: 1
      assert_no_text @data_export2.id
    end
  end
end
