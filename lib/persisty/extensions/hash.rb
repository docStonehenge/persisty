class Hash
  def to_mongo_value
    each_pair do |key, value|
      self[key] = value.respond_to?(:to_mongo_value) ? value.to_mongo_value : nil
    end
  end

  def present?
    !empty?
  end
end
