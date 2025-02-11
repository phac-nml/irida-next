# frozen_string_literal: true

# Append classes to the class list ensure only unique classes are present
module ClassNameHelper
  def class_names(*args)
    classes = []
    args.each do |class_name|
      classes.concat(class_name.split) if class_name.is_a?(String) && class_name.present?
      classes.concat(class_names_from_array(class_name)) if class_name.is_a?(Array)
      classes.concat(class_names_from_hash(class_name)) if class_name.is_a?(Hash)
    end
    classes.compact.sort.uniq.join(' ')
  end

  private

  def class_names_from_array(array)
    classes = []
    array.each do |class_name|
      classes.concat(class_names(class_name).split) if class_name
    end
    classes.split
  end

  def class_names_from_hash(hash)
    classes = []
    hash.each do |class_name, value|
      classes.concat(class_name.to_s.split) if value
    end
    classes
  end
end
