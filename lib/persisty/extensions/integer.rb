class Integer
  # Defines interface for ::try_convert class method, used on field coercion.
  # Tries to convert value into a Integer value.
  # Returns converted <tt>value</tt> when successful or +nil+ if conversion
  # raises an ArgumentError or TypeError.
  def self.try_convert(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def to_mongo_value
    self
  end

  def present?
    true
  end
end
