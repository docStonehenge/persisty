module Persisty
  module Persistence
    module DocumentDefinitions
      module Base
        include Comparable

        # Extends class-level behavior for entities, including document field definitions.
        # Sets <tt>fields_list</tt> and <tt>fields</tt> class instance variables,
        # to hold fields properties, with proper reader methods.
        # Finally, defines <tt>id</tt> attribute, to hold primary key values for entity,
        # aliasing to <tt>_id</tt>, according to MongoDB field with same name.
        def self.included(base)
          base.class_eval do
            extend(ClassMethods)

            @fields_list = [] # Collection of attributes set on entity, as symbols.
            @fields      = {} # Contains specifications of field names and types.

            define_field :id, type: BSON::ObjectId
            alias_method(:_id, :id)
            alias_method(:_id=, :id=)

            class << self
              attr_reader :fields_list, :fields
            end
          end
        end

        # Initializes instance using +fields+ specifications to set values.
        # Initialization can receive any set of attributes, with Symbol or String keys.
        # Field coercion is made on every attribute, given specifications on each field,
        # set by .field method.
        #
        # Examples
        #
        #   Entity.new
        #   #=> #<Entity:0x007fe9232bd0e0 @id=nil, @first_name=nil>
        #
        #   Entity.new(first_name: "John Doe")
        #   #=> #<Entity:0x007fe9232bd0e0 @id=nil, @first_name="John Doe">
        #
        #
        #   # Can initialize with 'id' attribute as 'id' or '_id':
        #
        #   Entity.new(id: BSON::ObjectId.new)
        #   #=> #<Entity:0x007fe9232bd0e0 @id=BSON::ObjectId('5a1246d46582e8676af472c7'), @first_name=nil>
        #
        #   Entity.new(_id: BSON::ObjectId.new)
        #   #=> #<Entity:0x007fe9232bd0e0 @id=BSON::ObjectId('5a1246d46582e8676af472c7'), @first_name=nil>
        #
        #
        #   # Any argument that isn't resolved as a field on entity, will be ignored.
        #
        #   Entity.new(foo: 1234)
        #   #=> #<Entity:0x007fe9232bd0e0 @id=nil, @first_name=nil>
        def initialize(attributes = {})
          attributes = attributes.each_with_object({}) do |(name, value), attrs|
            attrs[name.to_sym] = value
          end

          attributes[:id] = attributes[:_id] || attributes[:id]

          self.class.fields.each do |name, spec|
            instance_variable_set(
              :"@#{name}",
              Entities::Field.new(
                type: spec.dig(:type), value: attributes.dig(name)
              ).coerce
            )
          end
        end

        # Enables comparison with another entity object, using Comparable built-in behavior.
        # It raises a ComparisonError if caller doesn't have an id yet set, or
        # if the object to be compared to doesn't have an id.
        def <=>(other)
          if id.nil? or other.id.nil?
            raise Entities::ComparisonError
          end

          id <=> other.id
        end

        # Returns a Hash of all fields from entity, mapping keys as Symbols of field names
        # and their respective values.
        # <tt>include_id_field</tt> argument indicates if the Hash returned must
        # map the +id+ field or not.
        def to_hash(include_id_field: true)
          variables = instance_variables
          variables.delete(:@id) unless include_id_field

          {}.tap do |attrs|
            variables.each do |ivar|
              attrs[:"#{ivar.to_s.sub(/^@/, '')}"] = instance_variable_get(ivar)
            end
          end
        end

        # Returns a Hash of all fields from entity, mapping keys as Symbols of field names
        # and their respective values converted to MongoDB friendly values.
        # <tt>include_id_field</tt> argument indicated if +_id+ field must
        # be present on document-like structure returned, for insertions or queries.
        def to_mongo_document(include_id_field: true)
          document = to_hash(include_id_field: include_id_field)

          if include_id_field
            id_field = document.delete(:id)
            document[:_id] = id_field
          end

          document.to_mongo_value
        end

        module ClassMethods
          # Returns the class name of the repository to handle persistence on entity.
          # Should be overwritten by concrete DocumentDefinitions mixin created for entity.
          # Raises an NotImplementedError.
          def repository
            raise NotImplementedError
          end

          # Defines accessors methods for field <tt>name</tt>, considering <tt>type</tt> to use
          # coercion when setting value. Also, fills +fields_list+ with <tt>name</tt>
          # and +fields+ hash with <tt>name</tt> and <tt>type</tt>.
          # For any attributes besides 'id', calls registration of entity object
          # into current UnitOfWork.
          # When attribute is 'id', setter method will check if entity is detached:
          # if it is, then it's possible to change ID (considering that a detached entity
          # is't present on current UnitOfWork); if it is not, it raises an ArgumentError.
          #
          # Examples
          #
          #   class Entity
          #     ...
          #
          #     define_field :first_name, type: String
          #   end
          #
          #   Entity.fields_list
          #   #=> [:id, :first_name]
          #
          #   Entity.fields
          #   #=> {:id=>{:type=>BSON::ObjectId}, :first_name=>{:type=>String}
          #
          #   Entity.new.first_name = "John Doe"
          #   Entity.new.first_name
          #   #=> "John Doe"
          def define_field(name, type:)
            name = name.to_sym

            @fields_list.push(name)
            @fields[name] = { type: type }

            attr_reader name
            define_setter_method_for name, type
          end

          private

          def define_setter_method_for(attribute, type) # :nodoc:
            instance_eval do
              define_method("#{attribute}=") do |value|
                new_value = Entities::Field.new(type: type, value: value).coerce
                handle_registration_for_changes_on attribute, new_value
                instance_variable_set(:"@#{attribute}", new_value)
              end
            end
          end
        end

        private

        def handle_registration_for_changes_on(attribute, value) # :nodoc:
          if attribute == :id and !Persistence::UnitOfWork.current.detached? self
            raise ArgumentError,
                  'Cannot change ID from an entity that is still on current UnitOfWork'
          elsif instance_variable_get(:"@#{attribute}") != value
            Persistence::UnitOfWork.current.register_changed(self)
          end
        rescue Persistence::UnitOfWorkNotStartedError
        end
      end
    end
  end
end
