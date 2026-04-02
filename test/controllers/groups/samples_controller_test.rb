# frozen_string_literal: true

require 'test_helper'

module Groups
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
    end

    test 'should get index' do
      get group_samples_path(@group)
      assert_response :success

      w3c_validate 'Group Samples Page'
    end

    test 'should search' do
      post search_group_samples_url(@group),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: 'Sample 1' } } } } } },
           as: :turbo_stream
      assert_response :success
    end

    test 'should not search with invalid query' do
      post search_group_samples_url(@group),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: '' } } } } } },
           as: :turbo_stream
      assert_response :unprocessable_content
    end

    test 'should select samples' do
      timestamp = DateTime.current
      get select_group_samples_url(@group),
          params: { select: true, timestamp: timestamp },
          as: :turbo_stream
      assert_response :success
    end

    test 'should not select samples without permission' do
      sign_in users(:steve_doe)
      timestamp = DateTime.current
      get select_group_samples_url(@group),
          params: { select: true, timestamp: timestamp },
          as: :turbo_stream
      assert_response :unauthorized
    end

    test 'should handle metadata template none' do
      get group_samples_path(@group, params: { q: { metadata_template: 'none' } })
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('turbo-frame[src*="metadata_template=none"]')

      w3c_validate 'Group Samples Page'
    end

    test 'should handle metadata template all' do
      get group_samples_path(@group, params: { q: { metadata_template: 'all' } })
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('turbo-frame[src*="metadata_template=all"]')

      w3c_validate 'Group Samples Page'
    end

    test 'should handle specific metadata template' do
      template = metadata_templates(:valid_group_metadata_template)
      get group_samples_path(@group, params: { q: { metadata_template: template.id } })
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css("turbo-frame[src*=\"metadata_template=#{template.id}\"]")

      w3c_validate 'Group Samples Page'
    end

    test 'should not allow unauthorized access to index' do
      sign_in users(:steve_doe)
      get group_samples_path(@group)
      assert_response :unauthorized
    end

    test 'should store search params in session' do
      search_params = { name_or_puid_cont: 'test', sort: 'updated_at desc' }
      post search_group_samples_url(@group, params: { q: search_params }),
           as: :turbo_stream
      assert_response :success
      assert_equal search_params.stringify_keys,
                   session["samples_#{@group.id}_search_params"].stringify_keys
    end

    test 'should sort samples by project puid ascending' do
      get group_samples_path(@group, params: { q: { sort: 'namespaces.puid asc' }, limit: 50 })

      assert_response :success

      project_puids = rendered_project_puids
      assert_operator project_puids.size, :>, 1
      assert_operator project_puids.uniq.size, :>, 1

      project_puids.each_cons(2) do |left, right|
        assert_operator left, :<=, right
      end
    end

    test 'should sort samples by project puid descending' do
      get group_samples_path(@group, params: { q: { sort: 'namespaces.puid desc' }, limit: 50 })

      assert_response :success

      project_puids = rendered_project_puids
      assert_operator project_puids.size, :>, 1
      assert_operator project_puids.uniq.size, :>, 1

      project_puids.each_cons(2) do |left, right|
        assert_operator left, :>=, right
      end
    end

    test 'should apply default sort and support sorting group samples' do
      sample1 = samples(:sample1)
      sample2 = samples(:sample2)
      sample28 = samples(:sample28)
      sample29 = samples(:sample29)
      sample30 = samples(:sample30)
      sample31 = samples(:sample31)

      # default sort: updated_at desc (most recently updated first)
      get group_samples_path(@group)
      assert_response :success
      assert_first_rows_include(sample1.name, sample2.name, row_scope: '#samples-table-body')

      # sort by name asc
      get group_samples_path(@group), params: { q: { sort: 'name asc' } }
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_first_rows_include(sample1.name, sample2.name, row_scope: '#samples-table-body')

      # sort by name desc (sample30 and sample31 both named "Sample 2" sort first alphabetically)
      get group_samples_path(@group), params: { q: { sort: 'name desc' } }
      assert_response :success
      assert_sort_state(2, 'descending')
      assert_first_rows_include(sample30.name, sample31.name, row_scope: '#samples-table-body')

      # sort by puid asc (numeric suffix chars < alpha; sample28 AAAAAAAAA6, sample29 AAAAAAAAA7)
      get group_samples_path(@group), params: { q: { sort: 'puid asc' } }
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(sample28.puid, sample29.puid, row_scope: '#samples-table-body')

      # sort by puid desc (sample30 AAAAAAAABA is highest in group; sample25 AAAAAAAAAY is second)
      get group_samples_path(@group), params: { q: { sort: 'puid desc' } }
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(sample30.puid, samples(:sample25).puid, row_scope: '#samples-table-body')

      # sort by created_at asc (oldest first: sample31 at 34 weeks, sample30 at 33 weeks)
      get group_samples_path(@group), params: { q: { sort: 'created_at asc' } }
      assert_response :success
      assert_sort_state(4, 'ascending')
      assert_first_rows_include(sample31.name, sample30.name, row_scope: '#samples-table-body')

      # sort by created_at desc (newest first)
      get group_samples_path(@group), params: { q: { sort: 'created_at desc' } }
      assert_response :success
      assert_sort_state(4, 'descending')
      assert_first_rows_include(sample1.name, sample2.name, row_scope: '#samples-table-body')

      # sort by updated_at asc (oldest first: sample31 at 34 days, sample30 at 33 days)
      get group_samples_path(@group), params: { q: { sort: 'updated_at asc' } }
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_first_rows_include(sample31.name, sample30.name, row_scope: '#samples-table-body')
    end

    test 'should apply sort semantics to filtered group samples' do
      sample1 = samples(:sample1)
      sample2 = samples(:sample2)
      sample30 = samples(:sample30)

      get group_samples_path(@group), params: { q: { name_or_puid_cont: 'Sample 2', sort: 'puid desc' }, limit: 50 }

      assert_response :success
      assert_sort_state(1, 'descending')

      rendered_puids = rendered_sample_puids
      assert_includes rendered_puids, sample2.puid
      assert_includes rendered_puids, sample30.puid
      assert_not_includes rendered_puids, sample1.puid

      rendered_puids.each_cons(2) do |left, right|
        assert_operator left, :>=, right
      end
    end

    test 'should persist quick-search sort state across requests via session' do
      sample1 = samples(:sample1)
      sample2 = samples(:sample2)

      get group_samples_path(@group), params: { q: { name_or_puid_cont: sample1.puid, sort: 'name asc' } }
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_includes rendered_sample_puids, sample1.puid
      assert_not_includes rendered_sample_puids, sample2.puid

      get group_samples_path(@group)
      assert_response :success
      assert_sort_state(2, 'ascending')
      assert_includes rendered_sample_puids, sample1.puid
      assert_not_includes rendered_sample_puids, sample2.puid
    end

    test 'should clear metadata sort when metadata template is none' do
      get group_samples_path(@group), params: { q: { metadata_template: 'all', sort: 'metadata_metadatafield1 asc' } }

      assert_response :success
      assert_sort_state(8, 'ascending')

      get group_samples_path(@group), params: { q: { metadata_template: 'none' } }

      assert_response :success
      assert_sort_state(5, 'descending')
      assert_equal 'updated_at desc', session["samples_#{@group.id}_search_params"]['sort']
    end

    test 'accessing samples index on invalid page causes pagy overflow redirect at group level' do
      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get group_samples_path(@group, page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end

    private

    def rendered_project_puids
      doc = Nokogiri::HTML(response.body)
      doc.css('#samples-table table tbody tr td:nth-child(3)').map { |node| node.text.strip }
    end

    def rendered_sample_puids
      doc = Nokogiri::HTML(response.body)
      doc.css('#samples-table table tbody tr th:first-child').map { |node| node.text.strip }
    end
  end
end
