# frozen_string_literal: true

# non-database model for workflow metadata
class WorkflowMetadata
  include ActiveModel::Model

  attr_accessor :workflow_name, :workflow_version

  validates :workflow_name, presence: true
  validates :workflow_version, presence: true

  def initialize(**attrs)
    attrs.each do |attr, value|
      send("#{attr}=", value)
    end
  end

  def attributes
    %i[workflow_name workflow_version].each_with_object({}) do |hash, attr|
      hash[attr] = send(attr)
      hash
    end
  end

  # serialize metadata attributes
  class ArraySerializer
    class << self
      def load(arr)
        arr.map do |item|
          WorkflowMetadata.new(item)
        end
      end

      def dump(arr)
        arr.map(&:attributes)
      end
    end
  end
end
