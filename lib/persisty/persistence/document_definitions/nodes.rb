module Persisty
  module Persistence
    module DocumentDefinitions
      module Nodes
        def child_nodes(name, class_name: nil, cascade: false, foreign_key: nil)
          node_parser = CollectionNodeParser.new
          node_parser.parse_node_identification(name, class_name)
          node, klass = node_parser.node_name, node_parser.node_class
          register_child_node(node.to_sym, klass, cascade, foreign_key)
          collection_class = DocumentCollectionFactory.collection_for(klass)

          instance_eval do
            define_method("#{node}") do
              instance_variable_get("@#{node}") ||
                instance_variable_set(
                  "@#{node}", collection_class.new(self, klass, foreign_key)
                )
            end

            define_method("#{node}=") do |collection|
              instance_variable_set(
                "@#{node}",
                DocumentCollectionBuilder.new(
                  self, public_send("#{node}"), klass
                ).build_with(collection, foreign_key)
              )
            end
          end
        end

        def child_node(name, class_name: nil, cascade: false, foreign_key: nil)
          node, klass = parse_node_identification(name, class_name)
          register_child_node(node.to_sym, klass, cascade, foreign_key)

          child_set_parent_node = parent_node_on(
            klass, determine_parent_name_by_foreign_key(foreign_key)
          )

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
          foreign_key_field = node.to_foreign_key.to_sym
          register_defined_field foreign_key_field, BSON::ObjectId
          attr_reader foreign_key_field
          define_parent_node_handling_methods(node, klass, foreign_key_field)
        end

        def embed_child(name, class_name: nil, embedding_parent: nil)
          node, klass  = parse_node_identification(name, class_name)
          node, parent = node.to_sym, (embedding_parent || self.name).to_s.underscore.to_sym
          node_definition = { node: node, class: klass, cascade: false, foreign_key: nil }
          embedding_reference.register_child_node(parent, self, node_definition)
          klass.embedding_reference.register_child_node(parent, self, node_definition)
          attr_reader node

          instance_eval do
            define_method("#{node}=") do |embedded_child|
              NodeAssignments::CheckObjectType.(klass, node, embedded_child)
              current_child = instance_variable_get("@#{node}")
              return if current_child == embedded_child

              instance_variable_set("@#{node}", embedded_child)
              current_child&.instance_variable_set("@#{parent}", nil)
              embedded_child&.instance_variable_set("@#{parent}", self)
              Persistence::UnitOfWork.current.register_changed(self)
            end
          end
        end

        def embedding_parent(name, class_name: nil)
          node, klass = parse_node_identification(name, class_name)
          node = node.to_sym
          node_definition = { node: node, class: klass }
          embedding_reference.register_parent(node_definition)
          klass.embedding_reference.register_parent(node_definition)
          attr_reader node

          instance_eval do
            define_method("#{node}=") do |parent_object|
              NodeAssignments::CheckObjectType.(klass, node, parent_object)
              return if (current_parent = instance_variable_get("@#{node}")) == parent_object

              if current_parent
                current_parent.embeds.child_node_for(
                  node, current_parent.class, self.class
                ).each { |child| current_parent.public_send("#{child.name}=", nil) }

                Persistence::UnitOfWork.current.register_changed(current_parent)
              end

              if parent_object
                parent_object.embeds.child_node_for(
                  node, parent_object.class, self.class
                ).each { |child| parent_object.public_send("#{child.name}=", self) }

                Persistence::UnitOfWork.current.register_changed(parent_object)
              end

              instance_variable_set("@#{node}", parent_object)
            end
          end
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

        def register_child_node(node, node_class, cascade, foreign_key)
          type       = caller_locations.first.label.to_sym
          parent     = determine_parent_name_by_foreign_key(foreign_key)
          definition = { node: node, class: node_class, cascade: cascade, foreign_key: foreign_key }
          nodes_reference.public_send("register_#{type}", parent, self, definition)
          node_class.nodes_reference.public_send("register_#{type}", parent, self, definition)
        end

        def determine_parent_name_by_foreign_key(foreign_key)
          return name.underscore.to_sym unless foreign_key

          foreign_key.from_foreign_key.to_sym
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
            assign_foreign_key foreign_key_field, parent_object&.id
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
                filter: { child_set_parent_node.to_foreign_key => id }
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
    end
  end
end
