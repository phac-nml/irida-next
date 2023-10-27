# frozen_string_literal: true

module Viral
  # Viral component for attachments table colored labels
  class PillComponent < Viral::Component
    attr_reader :text

    COLORS = {
      blue: 'bg-blue-100 text-blue-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-blue-900 dark:text-blue-300',  # rubocop:disable Layout/LineLength
      gray: 'bg-gray-100 text-gray-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-gray-700 dark:text-gray-300',  # rubocop:disable Layout/LineLength
      red: 'bg-red-100 text-red-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-red-900 dark:text-red-300', # rubocop:disable Layout/LineLength
      green: 'bg-green-100 text-green-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-green-900 dark:text-green-300', # rubocop:disable Layout/LineLength
      yellow: 'bg-yellow-100 text-yellow-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-yellow-900 dark:text-yellow-300', # rubocop:disable Layout/LineLength
      indigo: 'bg-indigo-100 text-indigo-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-indigo-900 dark:text-indigo-300', # rubocop:disable Layout/LineLength
      purple: 'bg-purple-100 text-purple-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-purple-900 dark:text-purple-300', # rubocop:disable Layout/LineLength
      pink: 'bg-pink-100 text-pink-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded-full dark:bg-pink-900 dark:text-pink-300' # rubocop:disable Layout/LineLength
    }.freeze

    def initialize(
      text: nil,
      color: COLORS[:gray],
      **system_arguments
    )
      @text = text
      @color = if %w[format type].include?(color)
                 get_color(text) if text
               else
                 color.to_sym
               end
      @system_arguments = system_arguments
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        COLORS[@color]
      )
    end

    private

    def get_color(text)
      case text
      when 'fasta'
        :blue
      when 'fastq'
        :green
      when 'assembly'
        :pink
      when 'illumina_pe'
        :purple
      else
        :gray
      end
    end
  end
end
