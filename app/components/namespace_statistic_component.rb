class NamespaceStatisticComponent < Component
  attr_reader :id_prefix, :icon_name, :label_key, :count, :color_scheme

  def initialize(id_prefix:, icon_name:, label_key:, count:, color_scheme:)
    super
    @id_prefix = id_prefix.parameterize
    @icon_name = icon_name
    @label_key = label_key
    @count = count
    @color_scheme = color_scheme
  end

  def tailwind_colors
    slate_card_colors = {
      bg: 'bg-slate-50',
      dark_bg: 'dark:bg-slate-900',
      dark_border: 'dark:border-slate-700'
    }

    case color_scheme
    when :blue
      slate_card_colors.merge({
                                icon_bg: 'bg-blue-100',
                                dark_icon_bg: 'dark:bg-blue-700',
                                icon_text: 'text-blue-700',
                                dark_icon_text: 'dark:text-blue-200'
                              })
    when :teal
      slate_card_colors.merge({
                                icon_bg: 'bg-teal-100',
                                dark_icon_bg: 'dark:bg-teal-700',
                                icon_text: 'text-teal-700',
                                dark_icon_text: 'dark:text-teal-200'
                              })
    when :indigo
      slate_card_colors.merge({
                                icon_bg: 'bg-indigo-100',
                                dark_icon_bg: 'dark:bg-indigo-700',
                                icon_text: 'text-indigo-700',
                                dark_icon_text: 'dark:text-indigo-200'
                              })
    when :fuchsia
      slate_card_colors.merge({
                                icon_bg: 'bg-fuchsia-100',
                                dark_icon_bg: 'dark:bg-fuchsia-700',
                                icon_text: 'text-fuchsia-700',
                                dark_icon_text: 'dark:text-fuchsia-200'
                              })
    when :amber
      slate_card_colors.merge({
                                icon_bg: 'bg-amber-100',
                                dark_icon_bg: 'dark:bg-amber-700',
                                icon_text: 'text-amber-700',
                                dark_icon_text: 'dark:text-amber-200'
                              })
    else # default to slate for all parts
      {
        bg: 'bg-slate-50',
        dark_bg: 'dark:bg-slate-900',
        dark_border: 'dark:border-slate-700',
        icon_bg: 'bg-slate-100',
        dark_icon_bg: 'dark:bg-slate-700',
        icon_text: 'text-slate-700',
        dark_icon_text: 'dark:text-slate-200'
      }
    end
  end

  def icon_id_sm
    "#{id_prefix}-icon-sm"
  end

  def icon_id_lg
    "#{id_prefix}-icon-lg"
  end

  def label_id_lg
    "#{id_prefix}-label-lg"
  end
end
