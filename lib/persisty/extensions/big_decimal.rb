require 'bigdecimal'

class BigDecimal
  def self.try_convert(value)
    new(value, 8)
  rescue TypeError
    nil
  end

  def to_mongo_value
    to_f
  end

  def present?
    true
  end
end
