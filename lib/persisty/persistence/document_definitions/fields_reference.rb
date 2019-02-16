module Persisty
  module Persistence
    module DocumentDefinitions
      class FieldsReference
        attr_reader :fields

        def initialize
          @fields = {}
        end

        def register(name, type)
          fields[name] = { type: type }
        end

        def fields_list
          fields.keys
        end
      end
    end
  end
end
