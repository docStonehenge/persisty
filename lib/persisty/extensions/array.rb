class Array
  def to_mongo_value
    map! { |value| value.respond_to?(:to_mongo_value) ? value.to_mongo_value : nil }
    self
  end

  def present?
    !empty?
  end
end
