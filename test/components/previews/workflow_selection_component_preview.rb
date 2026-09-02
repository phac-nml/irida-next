# frozen_string_literal: true

class WorkflowSelectionComponentPreview < ViewComponent::Preview
  def default
    render WorkflowExecutions::WorkflowSelectionComponent.new(
      workflows:,
      namespace_id: 'a_namespace_id',
      sample_count: 5
    )
  end

  def min_samples_error
    render WorkflowExecutions::WorkflowSelectionComponent.new(
      workflows:,
      namespace_id: 'a_namespace_id',
      sample_count: 4
    )
  end

  def max_samples_error
    render WorkflowExecutions::WorkflowSelectionComponent.new(
      workflows:,
      namespace_id: 'a_namespace_id',
      sample_count: 11
    )
  end

  private

  def workflows
    [
      pipeline('Test Pipeline 3', '1.0.3', settings: { 'min_samples' => 5, 'max_samples' => 10 }),
      pipeline('Test Pipeline 2', '1.0.2'),
      pipeline('Test Pipeline 1', '1.0.1')
    ]
  end

  def pipeline(name, version, settings: nil)
    [
      name,
      Irida::Pipeline.new(
        'test/pipeline',
        {
          'name' => name,
          'description' => "A #{name.downcase}",
          'url' => 'http://example.com'
        },
        { 'name' => version, 'settings' => settings }.compact,
        nil,
        nil,
        unknown: true
      )
    ]
  end
end
