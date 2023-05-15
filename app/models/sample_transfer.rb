# frozen_string_literal: true

# entity class for SampleTransfer
class SampleTransfer
  include ActiveModel::Model

  attr_accessor :project, :samples
end
