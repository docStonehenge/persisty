class String
  def to_mongo_value
    self
  end

  def present?
    !strip.empty?
  end

  def underscore
    Persisty::StringModifiers::Underscorer.new.underscore(self)
  end
end
