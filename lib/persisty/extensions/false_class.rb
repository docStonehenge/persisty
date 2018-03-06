class FalseClass
  def to_mongo_value
    self
  end

  def present?
    self
  end
end
