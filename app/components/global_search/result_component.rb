# frozen_string_literal: true

module GlobalSearch
  # Component for rendering a single global search result
  class ResultComponent < Component
    with_collection_parameter :result

    TYPE_LABELS = {
      'projects' => :'global_search.index.types.projects',
      'groups' => :'global_search.index.types.groups',
      'workflow_executions' => :'global_search.index.types.workflow_executions',
      'samples' => :'global_search.index.types.samples',
      'data_exports' => :'global_search.index.types.data_exports'
    }.freeze

    TYPE_PILL_CLASSES = {
      'projects' => [
        'border border-blue-200 bg-blue-50/50 text-blue-700',
        'dark:border-blue-800/50 dark:bg-blue-900/20 dark:text-blue-300'
      ].join(' '),
      'groups' => [
        'border border-cyan-200 bg-cyan-50/50 text-cyan-700',
        'dark:border-cyan-800/50 dark:bg-cyan-900/20 dark:text-cyan-300'
      ].join(' '),
      'workflow_executions' => [
        'border border-amber-200 bg-amber-50/50 text-amber-700',
        'dark:border-amber-800/50 dark:bg-amber-900/20 dark:text-amber-300'
      ].join(' '),
      'samples' => [
        'border border-emerald-200 bg-emerald-50/50 text-emerald-700',
        'dark:border-emerald-800/50 dark:bg-emerald-900/20 dark:text-emerald-300'
      ].join(' '),
      'data_exports' => [
        'border border-rose-200 bg-rose-50/50 text-rose-700',
        'dark:border-rose-800/50 dark:bg-rose-900/20 dark:text-rose-300'
      ].join(' ')
    }.freeze

    def initialize(result:)
      @result = result
    end

    def type_label
      key = TYPE_LABELS[@result.type]
      key ? t(key) : @result.type.humanize
    end

    def type_pill_class
      TYPE_PILL_CLASSES[@result.type] || [
        'border border-slate-200 bg-slate-50/50 text-slate-700',
        'dark:border-slate-700/50 dark:bg-slate-800/20 dark:text-slate-300'
      ].join(' ')
    end
  end
end
