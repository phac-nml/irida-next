# frozen_string_literal: true

# Shared class recipes for host controls that participate in Pathogen toolbars
# but are not Pathogen::Toolbar::Button (e.g. DropdownComponent triggers).
module PathogenToolbarHelper
  # Pathogen small button classes for toolbar-density host triggers.
  # Defaults match Pathogen::Toolbar::Button (neutral + ghost).
  # Avoid w-full: full-width triggers fight mid-width flex wrap in Toolbar::Group.
  def pathogen_toolbar_trigger_classes(tone: :neutral, emphasis: :ghost)
    [
      Pathogen::ButtonStyles::BASE_CLASSES,
      Pathogen::ButtonStyles::STYLE_CLASSES.fetch(tone).fetch(emphasis),
      Pathogen::ButtonSizes::SIZE_MAPPINGS[:small],
      'shrink-0 gap-1'
    ].flatten.join(' ')
  end
end
