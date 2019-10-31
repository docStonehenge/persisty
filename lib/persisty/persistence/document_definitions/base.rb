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
            extend(ClassMethods)

            @fields_reference             = FieldsReference.new
            @nodes_reference              = NodesReference.new
            @parent_nodes_list            = []
            @parent_nodes_map             = {}
            @child_nodes_list             = []
            @child_nodes_map              = {}
            @child_nodes_collections_list = []
            @child_nodes_collections_map  = {}

            define_field :id, type: BSON::ObjectId
            alias_method(:_id, :id)
            alias_method(:_id=, :id=)

            class << self
              attr_reader :parent_nodes_list, :parent_nodes_map,
                          :child_nodes_list, :child_nodes_map,
                          :child_nodes_collections_list, :child_nodes_collections_map,
                          :nodes_reference

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

        def child_nodes_collections_list
          self.class.child_nodes_collections_list
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

          def child_nodes(name, class_name: nil, cascade: false, foreign_key: nil)
            node_parser = CollectionNodeParser.new
            node_parser.parse_node_identification(name, class_name)
            node, klass = node_parser.node_name, node_parser.node_class

            parent = (
              foreign_key.present? ? foreign_key.to_s.gsub(/_id$/, '') : self.name.underscore
            ).to_sym

            definition = { node: node.to_sym, class: klass, cascade: cascade, foreign_key: foreign_key }
            nodes_reference.register_child_nodes(parent, self, definition)
            klass.nodes_reference.register_child_nodes(parent, self, definition)

            register_defined_node(:child_nodes_collection, node, klass)
            collection_class = DocumentCollectionFactory.collection_for(klass)

            instance_eval do
              define_method("#{node}") do
                collection = instance_variable_get("@#{node}")
                return collection if collection

                instance_variable_set("@#{node}", collection_class.new(self, klass))
              end

              define_method("#{node}=") do |collection|
                instance_variable_set(
                  "@#{node}",
                  DocumentCollectionBuilder.new(
                    self, public_send("#{node}"), klass
                  ).build_with(collection)
                )
              end
            end
          end

          def child_node(name, class_name: nil, cascade: false, foreign_key: nil)
            node, klass = parse_node_identification(name, class_name)

            parent = (
              foreign_key.present? ? foreign_key.to_s.gsub(/_id$/, '') : self.name.underscore
            ).to_sym

            definition = { node: node.to_sym, class: klass, cascade: cascade, foreign_key: foreign_key }
            nodes_reference.register_child_node(parent, self, definition)
            klass.nodes_reference.register_child_node(parent, self, definition)

            register_defined_node(:child_node, node, klass)
            child_set_parent_node = parent_node_on(klass, parent)

            instance_eval do
              define_single_child_node_reader(node, klass, child_set_parent_node)
              define_single_child_node_writer(node, klass, child_set_parent_node)
            end
          end

          def parent_node(name, class_name: nil)
            node, klass = parse_node_identification(name, class_name)
            node_definition = { node: node.to_sym, class: klass }
            nodes_reference.register_parent(node_definition)
            klass.nodes_reference.register_parent(node_definition)
            register_defined_node(:parent_node, node, klass)

            foreign_key_field = (node + '_id').to_sym
            register_defined_field foreign_key_field, BSON::ObjectId
            attr_reader foreign_key_field

            define_parent_node_handling_methods(node, klass, foreign_key_field)
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

          def parse_node_identification(node_name, class_name)
            node_parser = NodeParser.new
            node_parser.parse_node_identification(node_name, class_name)
            [node_parser.node_name, node_parser.node_class]
          end

          def parent_node_on(klass, parent_node_name)
            klass.nodes_reference.parent_node_for(parent_node_name, self).name
          end

          def register_defined_field(name, type)
            @fields_reference.register(name, type)
          end

          def register_defined_node(node_type, name, node_class)
            instance_variable_get("@#{node_type}s_list").push(name.to_sym)
            instance_variable_get("@#{node_type}s_map")[name.to_sym] = node_class
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

          def define_parent_node_handling_methods(parent_node_name, parent_node_class, foreign_key_field)
            instance_eval do
              define_method("#{foreign_key_field}=") do |id|
                new_value = Entities::Field.(type: BSON::ObjectId, value: id)

                return if instance_variable_get(:"@#{foreign_key_field}") == new_value

                handle_registration_for_changes_on foreign_key_field, new_value do
                  instance_variable_set(:"@#{foreign_key_field}", new_value)
                end

                handle_current_parent_change(parent_node_name, new_value)
              end

              define_parent_node_writer(
                parent_node_name, parent_node_class, foreign_key_field
              )

              define_parent_node_reader(
                parent_node_name, parent_node_class, foreign_key_field
              )
            end
          end

          def define_parent_node_writer(name, parent_node_class, foreign_key_field)
            define_method("#{name}=") do |parent_object|
              NodeAssignments::CheckObjectType.(parent_node_class, name, parent_object)
              instance_variable_set("@#{name}", parent_object)
              public_send("#{foreign_key_field}=", parent_object&.id)
            end
          end

          def define_parent_node_reader(name, parent_node_class, foreign_key_field)
            define_method("#{name}") do
              if !instance_variable_get("@#{foreign_key_field}").nil? and instance_variable_get("@#{name}").nil?
                parent = Repositories::Registry[parent_node_class].find(
                  instance_variable_get("@#{foreign_key_field}")
                )

                instance_variable_set("@#{name}", parent)
                instance_variable_set("@#{foreign_key_field}", parent.id)
              end

              instance_variable_get("@#{name}")
            end
          end

          def define_single_child_node_reader(child_name, child_class, child_set_parent_node)
            define_method("#{child_name}") do
              if instance_variable_get("@#{child_name}").nil?
                child_obj = Repositories::Registry[child_class].find_all(
                  filter: { :"#{child_set_parent_node}_id" => id }
                ).first

                instance_variable_set("@#{child_name}", child_obj)
              end

              instance_variable_get("@#{child_name}")
            end
          end

          def define_single_child_node_writer(child_name, child_class, child_set_parent_node)
            define_method("#{child_name}=") do |child_obj|
              NodeAssignments::CheckObjectType.(child_class, child_name, child_obj)
              previous_child = instance_variable_get("@#{child_name}")

              return if previous_child and previous_child.id == child_obj&.id

              handle_previous_child_removal previous_child, child_set_parent_node
              child_obj&.public_send("#{child_set_parent_node}=", self)
              instance_variable_set("@#{child_name}", child_obj)
            end
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
            parent_nodes_list.include?(attr) or child_nodes_list.include?(attr)
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
      end
    end
  end
end
