class NilClass
  def to_mongo_value
    self
  end

  def present?
    false
  end
end
