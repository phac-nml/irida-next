# frozen_string_literal: true

class PathogenPaginationComponentPreview < ViewComponent::Preview
  # @!group Basic Usage
  # @label Default (Full Mode)
  # Default pagination with full mode showing page size selector, jump to page, and navigation
  # Tests:
  # - Full pagination interface
  # - Page size selection
  # - Jump to page functionality
  # - Navigation controls
  def default
    pagy = Pagy.new(count: 250, page: 3, items: 25)
    render_with_template(locals: {
                           pagy: pagy,
                           item_name: 'samples'
                         })
  end

  # @label Simple Mode
  # Simple pagination mode without page size selector or jump to page
  # Tests:
  # - Simplified interface
  # - Navigation only
  # - No page size controls
  def simple_mode
    pagy = Pagy.new(count: 150, page: 2, items: 50)
    render_with_template(template: 'pathogen_pagination_component_preview/simple_mode', locals: {
                           pagy: pagy,
                           item_name: 'projects'
                         })
  end

  # @label Custom Page Sizes
  # Pagination with custom page size options
  # Tests:
  # - Custom page size options
  # - Page size selection behavior
  def custom_page_sizes
    pagy = Pagy.new(count: 500, page: 1, items: 20)
    render_with_template(template: 'pathogen_pagination_component_preview/custom_page_sizes', locals: {
                           pagy: pagy,
                           item_name: 'records'
                         })
  end

  # @!endgroup

  # @!group Edge Cases
  # @label First Page
  # Pagination on the first page
  # Tests:
  # - First page navigation
  # - Disabled previous button
  # - Page range display
  def first_page
    pagy = Pagy.new(count: 100, page: 1, items: 25)
    render_with_template(template: 'pathogen_pagination_component_preview/edge_cases', locals: {
                           pagy: pagy,
                           item_name: 'items'
                         })
  end

  # @label Last Page
  # Pagination on the last page
  # Tests:
  # - Last page navigation
  # - Disabled next button
  # - Page range display
  def last_page
    pagy = Pagy.new(count: 100, page: 4, items: 25)
    render_with_template(template: 'pathogen_pagination_component_preview/edge_cases', locals: {
                           pagy: pagy,
                           item_name: 'items'
                         })
  end

  # @label Middle Page
  # Pagination in the middle of results
  # Tests:
  # - Middle page navigation
  # - Gap indicators
  # - Full navigation controls
  def middle_page
    pagy = Pagy.new(count: 1000, page: 15, items: 25)
    render_with_template(template: 'pathogen_pagination_component_preview/edge_cases', locals: {
                           pagy: pagy,
                           item_name: 'items'
                         })
  end

  # @label Single Page
  # Pagination with only one page of results
  # Tests:
  # - Single page behavior
  # - No navigation needed
  # - Component visibility
  def single_page
    pagy = Pagy.new(count: 10, page: 1, items: 25)
    render_with_template(template: 'pathogen_pagination_component_preview/edge_cases', locals: {
                           pagy: pagy,
                           item_name: 'items'
                         })
  end

  # @label Empty Results
  # Pagination with no results (should not render)
  # Tests:
  # - Empty state handling
  # - Component visibility
  def empty_results
    pagy = Pagy.new(count: 0, page: 1, items: 25)
    render_with_template(template: 'pathogen_pagination_component_preview/edge_cases', locals: {
                           pagy: pagy,
                           item_name: 'items'
                         })
  end

  # @!endgroup

  # @!group Different Item Types
  # @label Samples
  # Pagination for sample items
  # Tests:
  # - Sample-specific item naming
  # - Proper pluralization
  def samples
    pagy = Pagy.new(count: 75, page: 2, items: 20)
    render_with_template(template: 'pathogen_pagination_component_preview/item_types', locals: {
                           pagy: pagy,
                           item_name: 'sample'
                         })
  end

  # @label Projects
  # Pagination for project items
  # Tests:
  # - Project-specific item naming
  # - Proper pluralization
  def projects
    pagy = Pagy.new(count: 45, page: 3, items: 15)
    render_with_template(template: 'pathogen_pagination_component_preview/item_types', locals: {
                           pagy: pagy,
                           item_name: 'project'
                         })
  end

  # @label Workflow Executions
  # Pagination for workflow execution items
  # Tests:
  # - Workflow execution-specific item naming
  # - Proper pluralization
  def workflow_executions
    pagy = Pagy.new(count: 200, page: 5, items: 30)
    render_with_template(template: 'pathogen_pagination_component_preview/item_types', locals: {
                           pagy: pagy,
                           item_name: 'workflow execution'
                         })
  end

  # @!endgroup

  # @!group Large Datasets
  # @label Many Pages
  # Pagination with many pages showing gap indicators
  # Tests:
  # - Gap indicator display
  # - Large dataset handling
  # - Performance with many pages
  def many_pages
    pagy = Pagy.new(count: 5000, page: 50, items: 25)
    render_with_template(template: 'pathogen_pagination_component_preview/large_datasets', locals: {
                           pagy: pagy,
                           item_name: 'items'
                         })
  end

  # @label Large Page Size
  # Pagination with large page sizes
  # Tests:
  # - Large page size handling
  # - Page size selector behavior
  def large_page_size
    pagy = Pagy.new(count: 1000, page: 1, items: 100)
    render_with_template(template: 'pathogen_pagination_component_preview/large_page_size', locals: {
                           pagy: pagy,
                           item_name: 'items'
                         })
  end

  # @!endgroup
end
