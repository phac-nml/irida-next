# frozen_string_literal: true

# Index existing Samples using SearchKick
class IndexExistingSamples < ActiveRecord::Migration[7.2]
  def up
    Sample.reindex
  end
end
