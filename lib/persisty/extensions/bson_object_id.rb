module BSON
  class ObjectId
    def self.try_convert(value)
      from_string(value)
    rescue Invalid
      nil
    end

    def to_mongo_value
      self
    end

    def present?
      to_s.present?
    end
  end
end
