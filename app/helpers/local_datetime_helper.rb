# frozen_string_literal: true

# Helper to help return and manipulate local_time/local_date gem
module LocalDatetimeHelper
  # called by pathogen datepicker
  def datepicker_expiry_default_min_date
    extract_date(helpers.local_date(Date.today + 1.day, '%Y-%m-%d'))
  end

  private

  # Extracts the date from local_date
  # Example of what we receive from local_time:
  # <time datetime="2025-07-31T00:00:00Z" data-local="time" data-format="%B %d, %Y" title="July 30, 2025 at 7:00pm CDT"
  # data-processed-at="2025-08-06T16:23:59.156Z" data-localized="">
  # July 30, 2025
  # </time>
  # extract out "July 30, 2025"
  def extract_date(date)
    date.split('>').pop.split('</')[0]
  rescue StandardError
    ''
  end
end
