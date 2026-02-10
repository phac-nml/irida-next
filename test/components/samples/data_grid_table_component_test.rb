# frozen_string_literal: true

require 'view_component_test_case'

module Samples
  class DataGridTableComponentTest < ViewComponentTestCase
    test 'renders data grid with sample rows' do
      samples = [samples(:sample1), samples(:sample2)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector '.pathogen-data-grid__table'
      assert_selector 'th', text: 'Sample PUID'
      assert_selector 'td', text: samples.first.puid
    end

    test 'renders empty state when samples are absent' do
      pagy = Pagy.new(count: 0, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      [],
                      namespace,
                      pagy,
                      has_samples: false,
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector '.empty_state_message', text: 'No Samples'
      assert_no_selector '.pathogen-data-grid__table'
    end

    test 'renders project column for group namespace' do
      samples = [samples(:sample1)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = groups(:group_one)

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector 'th', text: 'Project'
      assert_selector '.pathogen-data-grid__table'
    end

    test 'does not render project column for project namespace' do
      samples = [samples(:sample1)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_no_selector 'th', text: 'Project'
      assert_selector '.pathogen-data-grid__table'
    end

    test 'limits metadata fields when exceeding calculated maximum' do
      samples = [samples(:sample1), samples(:sample2)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      # Create more metadata fields than the limit (clamped to MAX_METADATA_FIELDS_SIZE = 200)
      many_fields = (1..1500).map { |i| "field_#{i}" }

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      metadata_fields: many_fields,
                      abilities: { edit_sample_metadata: false },
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      # Should show warning message
      assert_selector '[role="status"][aria-live="polite"]'
      assert_text 'The number of metadata fields has been limited'
    end

    test 'shows warning with link when user can edit metadata' do
      samples = [samples(:sample1)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      # Create enough fields to trigger warning (2000 / 1 = 2000, but max is 200)
      many_fields = (1..250).map { |i| "field_#{i}" }

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      metadata_fields: many_fields,
                      abilities: { edit_sample_metadata: true },
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector '[role="status"][aria-live="polite"]'
      assert_text 'create a metadata template with those fields'
      assert_selector 'a.font-semibold.underline'
    end

    test 'shows warning without link when user cannot edit metadata' do
      samples = [samples(:sample1)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      many_fields = (1..250).map { |i| "field_#{i}" }

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      metadata_fields: many_fields,
                      abilities: { edit_sample_metadata: false },
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector '[role="status"][aria-live="polite"]'
      assert_no_selector 'a', text: 'create a metadata template with those fields'
    end

    test 'renders sticky columns for PUID and Name' do
      samples = [samples(:sample1)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      # Check for sticky column CSS classes
      assert_selector 'th.pathogen-data-grid__cell--sticky', count: 2
    end

    test 'highlights search term in sample names and PUIDs' do
      samples = [samples(:sample1)]
      pagy = Pagy.new(count: samples.size, page: 1, limit: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      search_params: { name_or_puid_cont: 'Sample' },
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector 'mark.bg-primary-300'
    end

    test 'renders metadata field values' do
      sample = samples(:sample1)
      sample.metadata = { 'test_field' => 'test_value' }
      sample.save!

      pagy = Pagy.new(count: 1, page: 1, items: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      [sample],
                      namespace,
                      pagy,
                      has_samples: true,
                      metadata_fields: ['test_field'],
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector 'th', text: 'test_field'
      assert_selector 'td', text: 'test_value'
    end
  end
end
