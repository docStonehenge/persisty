class String
  def to_mongo_value
    self
  end

  def present?
    !strip.empty?
  end
end
