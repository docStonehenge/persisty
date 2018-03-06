class Date
  def self.try_convert(value)
    parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def to_mongo_value
    self
  end

  def present?
    true
  end
end
