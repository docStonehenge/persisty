class Symbol
  def to_mongo_value
    to_s.to_mongo_value
  end

  def present?
    to_s.present?
  end

  def to_foreign_key
    Persisty::StringModifiers::ForeignKeyBuilder.new.build_foreign_key_from(self).to_sym
  end

  def from_foreign_key
    Persisty::StringModifiers::ForeignKeyBuilder.new.name_from_foreign_key(self).to_sym
  end
end
