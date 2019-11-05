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

  def to_foreign_key
    Persisty::StringModifiers::ForeignKeyBuilder.new.build_foreign_key_from(self)
  end

  def from_foreign_key
    Persisty::StringModifiers::ForeignKeyBuilder.new.name_from_foreign_key(self)
  end
end
