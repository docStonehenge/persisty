module Persisty
  module Persistence
    module Entities
      class Field
        COERCION_MAP = {
          'datetime' => DateTime, 'date' => Date, 'time' => Time,
          'string' => String, 'array' => Array, 'hash' => Hash,
          'bigdecimal' => BigDecimal, 'float' => Float,
          'integer' => Integer, 'bson::objectid' => BSON::ObjectId,
          'persisty::boolean' => Persisty::Boolean
        }.freeze

        def self.call(type:, value:)
          new(type: type, value: value).coerce
        end

        def initialize(type:, value:)
          @type, @value = type, value
        end

        def coerce
          types = COERCION_MAP.values

          unless types.include? @type
            raise(ArgumentError, "Expected 'type' can be only #{types.join(', ')}.")
          end

          COERCION_MAP[@type.name.downcase].try_convert(@value)
        end
      end
    end
  end
end
