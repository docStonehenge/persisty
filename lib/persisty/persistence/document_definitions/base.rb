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

            @fields_list       = [] # Collection of attributes set on entity, as symbols.
            @fields            = {} # Contains specifications of field names and types.
            @parent_nodes_list = []
            @parent_nodes_map  = {}
            @child_nodes_list  = []
            @child_nodes_map   = {}

            define_field :id, type: BSON::ObjectId
            alias_method(:_id, :id)
            alias_method(:_id=, :id=)

            class << self
              attr_reader :fields_list, :fields,
                          :parent_nodes_list, :parent_nodes_map,
                          :child_nodes_list, :child_nodes_map
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

          initialize_fields_with attributes
          initialize_nodes_based_on attributes
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
        # and their respective values, without including any relations.
        # <tt>include_id_field</tt> argument indicates if the Hash returned must
        # map the +id+ field or not.
        def to_hash(include_id_field: true)
          variables = instance_variables
          parent_nodes_list.each { |node| variables.delete(:"@#{node}") }

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

        def fields
          self.class.fields
        end

        def set_foreign_key_for(klass, foreign_key)
          parent_node = self.class.parent_nodes_map.key(klass)
          raise Errors::NoParentNodeError unless parent_node
          public_send("#{parent_node}_id=", foreign_key)
        end

        def parent_nodes_list
          self.class.parent_nodes_list
        end

        def child_nodes_list
          self.class.child_nodes_list
        end

        def child_nodes_map
          self.class.child_nodes_map
        end

        module ClassMethods
          # Returns the class name of the repository to handle persistence on entity.
          # Should be overwritten by concrete DocumentDefinitions mixin created for entity.
          # Raises an NotImplementedError.
          def repository
            raise NotImplementedError
          end

          def child_node(name, class_name: nil)
            child, child_klass = normalize_node_identification(name, class_name)
            register_defined_node(:child_node, child, child_klass)
            child_set_parent_node = parent_node_on(child_klass)

            instance_eval do
              define_single_child_node_reader(child, child_klass, child_set_parent_node)
              define_single_child_node_writer(child, child_klass, child_set_parent_node)
            end
          end

          def parent_node(name, class_name: nil)
            parent_name, parent_klass = normalize_node_identification(name, class_name)
            register_defined_node(:parent_node, parent_name, parent_klass)

            foreign_key_field = (parent_name + '_id').to_sym
            register_defined_field foreign_key_field, BSON::ObjectId
            attr_reader foreign_key_field

            define_parent_node_handling_methods(
              parent_name, parent_klass, foreign_key_field
            )
          end

          # Defines accessors methods for field <tt>name</tt>, considering <tt>type</tt> to use
          # coercion when setting value. Also, fills +fields_list+ with <tt>name</tt>
          # and +fields+ hash with <tt>name</tt> and <tt>type</tt>.
          # For any attributes besides 'id', calls registration of entity object
          # into current UnitOfWork.
          # When attribute is 'id', writer method will check if entity is detached:
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
          #   entity = Entity.new
          #   entity.first_name = "John Doe"
          #   entity.first_name
          #   #=> "John Doe"
          def define_field(name, type:)
            name = name.to_sym
            register_defined_field name, type
            attr_reader name
            define_writer_method_for name, type
          end

          private

          def normalize_node_identification(node_name, class_name)
            name  = StringModifiers::Underscorer.new.underscore(node_name.to_s)
            klass = determine_node_class(name, class_name)

            [name, klass]
          end

          def determine_node_class(node_name, class_name)
            return Object.const_get(class_name.to_s) if class_name
            Object.const_get(StringModifiers::Camelizer.new.camelize(node_name))
          end

          def parent_node_on(child_klass)
            unless (node_name = child_klass.parent_nodes_map.key(self))
              raise Errors::NoParentNodeError
            end

            node_name
          end

          def register_defined_field(name, type)
            @fields_list.push(name)
            @fields[name] = { type: type }
          end

          def register_defined_node(node_type, name, node_klass)
            instance_variable_get("@#{node_type}s_list").push(name.to_sym)
            instance_variable_get("@#{node_type}s_map")[name.to_sym] = node_klass
          end

          def define_writer_method_for(attribute, type) # :nodoc:
            instance_eval do
              define_method("#{attribute}=") do |value|
                new_value = Entities::Field.new(type: type, value: value).coerce
                handle_registration_for_changes_on attribute do
                  instance_variable_set(:"@#{attribute}", new_value)
                end
              end
            end
          end

          def define_parent_node_handling_methods(parent_node_name, parent_node_klass, foreign_key_field)
            instance_eval do
              define_method("#{foreign_key_field}=") do |id|
                new_value = Entities::Field.new(type: BSON::ObjectId, value: id).coerce

                return if instance_variable_get(:"@#{foreign_key_field}") == new_value

                handle_registration_for_changes_on foreign_key_field do
                  instance_variable_set(:"@#{foreign_key_field}", new_value)
                end

                handle_current_parent_change(parent_node_name, new_value)
              end

              define_parent_node_writer(
                parent_node_name, parent_node_klass, foreign_key_field
              )

              define_parent_node_reader(
                parent_node_name, parent_node_klass, foreign_key_field
              )
            end
          end

          def define_parent_node_writer(name, parent_node_klass, foreign_key_field)
            define_method("#{name}=") do |parent_object|
              check_object_type_based_on(parent_node_klass, name, parent_object)
              instance_variable_set("@#{name}", parent_object)
              public_send("#{foreign_key_field}=", parent_object&.id)
            end
          end

          def define_parent_node_reader(name, parent_node_klass, foreign_key_field)
            define_method("#{name}") do
              if !instance_variable_get("@#{foreign_key_field}").nil? and instance_variable_get("@#{name}").nil?
                parent = DocumentManager.new.find(
                  parent_node_klass, instance_variable_get("@#{foreign_key_field}")
                )

                instance_variable_set("@#{name}", parent)
                instance_variable_set("@#{foreign_key_field}", parent.id)
              end

              instance_variable_get("@#{name}")
            end
          end

          def define_single_child_node_reader(child_name, child_klass, child_set_parent_node)
            define_method("#{child_name}") do
              if instance_variable_get("@#{child_name}").nil?
                child_obj = DocumentManager.new.find_all(
                  child_klass, filter: { :"#{child_set_parent_node}_id" => id }
                ).first

                instance_variable_set("@#{child_name}", child_obj)
              end

              instance_variable_get("@#{child_name}")
            end
          end

          def define_single_child_node_writer(child_name, child_klass, child_set_parent_node)
            define_method("#{child_name}=") do |child_obj|
              check_object_type_based_on(child_klass, child_name, child_obj)
              previous_child = instance_variable_get("@#{child_name}")

              return if previous_child and previous_child.id == child_obj&.id

              handle_previous_child_removal previous_child, child_set_parent_node
              child_obj.public_send("#{child_set_parent_node}=", self) if child_obj
              instance_variable_set("@#{child_name}", child_obj)
            end
          end
        end

        private

        def check_object_type_based_on(node_klass, node_name, object)
          return if object.nil? or object.is_a? node_klass
          raise TypeError, "Object is a type mismatch from defined node '#{node_name}'"
        end

        def handle_previous_child_removal(previous_child, parent_node_name)
          return unless previous_child and previous_child.public_send(parent_node_name) == self
          previous_child.public_send("#{parent_node_name}=", nil)
          DocumentManager.new.remove(previous_child)
        end

        def handle_current_parent_change(parent_node_name, new_parent_id)
          return unless (current_parent = instance_variable_get(:"@#{parent_node_name}"))

          if current_parent.id and current_parent.id != new_parent_id
            current_parent.public_send(
              "#{current_parent.child_nodes_map.key(self.class)}=", nil
            )

            instance_variable_set(:"@#{parent_node_name}", nil)
          end
        end

        def initialize_fields_with(attributes)
          fields.each do |name, spec|
            instance_variable_set(
              :"@#{name}",
              Entities::Field.new(
                type: spec.dig(:type), value: attributes.dig(name)
              ).coerce
            )
          end
        end

        def initialize_nodes_based_on(attributes)
          attributes.select do |attr|
            parent_nodes_list.include?(attr) or child_nodes_list.include?(attr)
          end.each { |node, value| public_send("#{node}=", value) }
        end

        def handle_registration_for_changes_on(attribute) # :nodoc:
          if attribute == :id and !Persistence::UnitOfWork.current.detached? self
            raise ArgumentError,
                  'Cannot change ID from an entity that is still on current UnitOfWork'
          end

          yield
          Persistence::UnitOfWork.current.register_changed(self)
        rescue Persistence::UnitOfWorkNotStartedError
          yield
        end
      end
    end
  end
end
