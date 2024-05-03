# frozen_string_literal: true

module Viral
  # Viral component for attachments table colored labels
  class PillComponent < Viral::Component
    attr_reader :text

    COLORS = {
      blue: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
      slate: 'bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300',
      red: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
      green: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
      yellow: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
      indigo: 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300',
      purple: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
      pink: 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300',
      primary: 'bg-primary-100 text-primary-800 dark:bg-primary-800 dark:text-primary-400',
      transparent: 'text-slate-500 dark:text-slate-400'
    }.freeze

    BORDER_COLORS = {
      blue: 'border border-blue-800 dark:border-blue-300',
      slate: 'border border-slate-800 dark:border-slate-300',
      red: 'border border-red-800 dark:border-red-300',
      green: 'border border-green-800 dark:border-green-300',
      yellow: 'border border-yellow-800 dark:border-yellow-300',
      indigo: 'border border-indigo-800 dark:border-indigo-300',
      purple: 'border border-purple-800 dark:border-purple-300',
      pink: 'border border-pink-800 dark:border-pink-300',
      primary: 'border border-primary-800 dark:border-primary-400',
      transparent: 'border border-slate-500 dark:border-slate-400'
    }.freeze

    def initialize(
      text: nil,
      color: nil,
      border: false,
      **system_arguments
    )
      @text = text
      @color = color.to_sym if color
      border = BORDER_COLORS[@color] if border
      @system_arguments = system_arguments
      @system_arguments[:classes] = class_names(
        COLORS[@color],
        border,
        # Tailwind classes pertaining to all pill component colors
        'text-xs font-medium px-2.5 py-0.5 rounded-full',
        @system_arguments[:classes]
      )
    end
  end
end
