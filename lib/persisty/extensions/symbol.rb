class Symbol
  def to_mongo_value
    to_s.to_mongo_value
  end

  def present?
    to_s.present?
  end
end
