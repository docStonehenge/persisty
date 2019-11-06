module Persisty
  module Persistence
    module DocumentDefinitions
      module Base
        include Comparable

        # Extends class-level behavior for entities, including document field definitions.
        # Sets <tt>fields_reference</tt> class instance variable,
        # to hold fields properties, with proper reader methods.
        # Finally, defines <tt>id</tt> attribute, to hold primary key values for entity,
        # aliasing to <tt>_id</tt>, according to MongoDB field with same name.
        def self.included(base)
          base.class_eval do
            extend(ClassMethods, DocumentDefinitions::Nodes)

            @fields_reference    = FieldsReference.new
            @nodes_reference     = NodesReference.new(self)
            @embedding_reference = NodesReference.new(self)

            define_field :id, type: BSON::ObjectId
            alias_method(:_id, :id)
            alias_method(:_id=, :id=)

            class << self
              attr_reader :nodes_reference, :embedding_reference

              def fields
                @fields_reference.fields
              end

              def fields_list
                @fields_reference.fields_list
              end
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

        # Enables comparison with another entity object.
        # Uses ancestor behavior when argument isn't from caller class.
        def <=>(other)
          return super unless other.is_a?(self.class)
          return object_id <=> other.object_id if [id, other.id].any?(&:nil?)

          id <=> other.id
        end

        # Returns a Hash of all fields from entity, mapping keys as Symbols of field names
        # and their respective values, without including any relations.
        # <tt>include_id_field</tt> argument indicates if the Hash returned must
        # map the +id+ field or not.
        def _raw_fields(include_id_field: true)
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
        # It is used internally by repositories to map values from entities to
        # documents on the database.
        def _as_mongo_document(include_id_field: true)
          document = _raw_fields(include_id_field: include_id_field)

          if include_id_field
            id_field = document.delete(:id)
            document[:_id] = id_field
          end

          document.to_mongo_value
        end

        def fields
          self.class.fields
        end

        def nodes
          self.class.nodes_reference
        end

        def parent_nodes_list
          nodes.parent_nodes_list
        end

        def assign_foreign_key(foreign_key_name, id)
          public_send("#{foreign_key_name}=", id)
        end

        %i[child_node child_nodes].each do |type|
          define_method("#{type}_list") { nodes.public_send(__callee__) }

          define_method("cascading_#{type}_objects") do
            nodes.public_send("cascading_#{type}_with_foreign_key").map do |node|
              [public_send(node[0]), node[1]]
            end.reject { |node| node[0].nil? }
          end
        end

        private

        def handle_previous_child_removal(previous_child, parent_node_name)
          return unless previous_child and previous_child.public_send(parent_node_name) == self
          previous_child.public_send("#{parent_node_name}=", nil)
          Persistence::UnitOfWork.current.register_removed(previous_child)
        end

        def handle_current_parent_change(parent_node_name, new_parent_id)
          current_parent = instance_variable_get(:"@#{parent_node_name}")
          return unless different_parent?(new_parent_id, current_parent)

          current_parent.nodes.child_nodes_for(
            parent_node_name.to_sym, current_parent.class, self.class
          ).each do |node|
            current_parent.public_send(node.name).remove(self)
            instance_variable_set(:"@#{parent_node_name}", nil)
            change_parent_collection node.name, parent_node_name, new_parent_id
          end

          current_parent.nodes.child_node_for(
            parent_node_name.to_sym, current_parent.class, self.class
          ).each { |node| current_parent.public_send("#{node.name}=", nil) }

          instance_variable_set(:"@#{parent_node_name}", nil)
        end

        def different_parent?(new_parent_id, current_parent)
          return false unless current_parent
          current_parent.id and current_parent.id != new_parent_id
        end

        def change_parent_collection(collection, parent_node, new_parent_id)
          return unless new_parent_id
          public_send(parent_node).public_send(collection).push(self)
        end

        def initialize_fields_with(attributes)
          fields.each do |name, spec|
            instance_variable_set(
              :"@#{name}",
              Entities::Field.(type: spec.dig(:type), value: attributes.dig(name))
            )
          end
        end

        def initialize_nodes_based_on(attributes)
          attributes.select do |attr|
            parent_nodes_list.include?(attr) or child_node_list.include?(attr)
          end.each { |node, value| public_send("#{node}=", value) }
        end

        def handle_registration_for_changes_on(attribute, new_value) # :nodoc:
          current_value = public_send(attribute)

          if attribute == :id and !current_value.nil? and current_value != new_value
            raise ArgumentError,
                  'Cannot change ID when a previous value is already assigned.'
          end

          yield

          Persistence::UnitOfWork.current.register_changed(self)
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

          def register_defined_field(name, type)
            @fields_reference.register(name, type)
          end

          def define_writer_method_for(attribute, type) # :nodoc:
            instance_eval do
              define_method("#{attribute}=") do |value|
                new_value = Entities::Field.(type: type, value: value)
                handle_registration_for_changes_on attribute, new_value do
                  instance_variable_set(:"@#{attribute}", new_value)
                end
              end
            end
          end
        end
      end
    end
  end
end
