module Persisty
  module Persistence
    module DocumentDefinitions
      describe NodesReference do
        include_context 'StubEntity'

        context 'as a Hash' do
          it 'delegates key related methods to nodes hash' do
            expect(subject).to respond_to(:keys)
            expect(subject).to respond_to(:key?)
            expect(subject).to respond_to(:has_key?)
          end

          it 'delegates value related methods to nodes hash' do
            expect(subject).to respond_to(:values)
            expect(subject).to respond_to(:value?)
            expect(subject).to respond_to(:has_value?)
          end
        end

        describe 'register_parent node_definition' do
          it 'registers node definition correctly as a parent' do
            subject.register_parent node: :foo, class: ::StubEntity

            expect(
              subject.instance_variable_get(:@nodes)
            ).to include(
                   { node: :foo, class: ::StubEntity } => {
                     child_node: [], child_nodes: []
                   }
                 )
          end

          it 'allows to register parent node definition with only a different node' do
            subject.register_parent node: :foo, class: ::StubEntity
            subject.register_parent node: :bar, class: ::StubEntity

            expect(
              subject.instance_variable_get(:@nodes)
            ).to include(
                   { node: :foo, class: ::StubEntity } => {
                     child_node: [], child_nodes: []
                   },
                   { node: :bar, class: ::StubEntity } => {
                     child_node: [], child_nodes: []
                   }
                 )
          end

          context 'when node_definition is invalid' do
            it 'raises error when nodes already has key with same node and class' do
              subject.register_parent node: :foo, class: ::StubEntity

              expect {
                subject.register_parent node: :foo, class: ::StubEntity
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'parent definition already registered')
            end

            it 'raises error when nodes already has key with only same node' do
              subject.register_parent node: :foo, class: ::StubEntity

              expect {
                subject.register_parent node: :foo, class: ::String
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'parent definition already registered')
            end

            it "raises error when node key isn't present" do
              expect {
                subject.register_parent test: :foo, class: ::StubEntity
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :node')
            end

            it "raises error when class key isn't present" do
              expect {
                subject.register_parent node: :foo, foo: ::StubEntity
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :class')
            end

            it "raises error when node definition doesn't have size of two" do
              expect {
                subject.register_parent node: :foo, class: ::StubEntity, cascade: false
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')

              expect {
                subject.register_parent node: :foo, class: ::StubEntity, cascade: false, foo: :bar
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')
            end
          end
        end

        describe '#register_child_node parent_node, parent_class, node_definition' do
          context 'when parent is already registered' do
            before do
              subject.register_parent(node: :foo, class: ::String)
            end

            it 'register child_node under parent' do
              subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil })

              expect(
                subject.instance_variable_get(:@nodes)
              ).to include(
                     { node: :foo, class: ::String } => {
                       child_node: [
                         { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil }
                       ],
                       child_nodes: []
                     }
                   )
            end

            it "raises error when node definition doesn't have size of four" do
              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')

              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: false })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')
            end

            it 'raises error when nodes already has key with same node and class' do
              subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil })

              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'child_node definition already registered')
            end

            it 'raises error when nodes already has key with same node and class but different cascade' do
              subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil })

              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'child_node definition already registered')
            end

            it 'raises error when nodes already has key with only same node' do
              subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil })

              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::Array, cascade: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'child_node definition already registered')
            end

            it "raises error when node key isn't present" do
              expect {
                subject.register_child_node(:foo, String, { test: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :node')
            end

            it "raises error when class key isn't present" do
              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, test: ::StubEntity, cascade: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :class')
            end

            it "raises error when cascade key isn't present" do
              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, test: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :cascade')
            end

            it "raises error when foreign_key key isn't present" do
              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: true, fooza: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :foreign_key')
            end
          end

          context "when parent node isn't registered yet" do
            it 'raises Errors::NoParentNodeError' do
              expect {
                subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: :foo_id })
              }.to raise_error(Errors::NoParentNodeError)
            end
          end
        end

        describe '#register_child_nodes parent_node, parent_class, node_definition' do
          context 'when parent is already registered' do
            before do
              subject.register_parent(node: :foo, class: ::String)
            end

            it 'register child_nodes under parent' do
              subject.register_child_nodes(
                :foo, String,
                { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil }
              )

              expect(
                subject.instance_variable_get(:@nodes)
              ).to include(
                     { node: :foo, class: ::String } => {
                       child_node: [],
                       child_nodes: [
                         { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil }
                       ]
                     }
                   )
            end

            it "raises error when node definition doesn't have size of four" do
              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')

              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: false })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')
            end

            it 'raises error when nodes already has key with same node and class' do
              subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: false, foreign_key: nil })

              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: false, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'child_nodes definition already registered')
            end

            it 'raises error when nodes already has key with same node and class but different cascade' do
              subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil })

              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: false, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'child_nodes definition already registered')
            end

            it 'raises error when nodes already has key with only same node' do
              subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil })

              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::Array, cascade: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'child_nodes definition already registered')
            end

            it "raises error when node key isn't present" do
              expect {
                subject.register_child_nodes(:foo, String, { test: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :node')
            end

            it "raises error when class key isn't present" do
              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, test: ::StubEntity, cascade: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :class')
            end

            it "raises error when cascade key isn't present" do
              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, test: true, foreign_key: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :cascade')
            end

            it "raises error when foreign_key key isn't present" do
              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: false, fooza: nil })
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :foreign_key')
            end
          end

          context "when parent node isn't registered yet" do
            it 'raises Errors::NoParentNodeError' do
              expect {
                subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil })
              }.to raise_error(Errors::NoParentNodeError)
            end
          end
        end

        describe '#parent_node_for node_name, klass' do
          context 'when node definition is present' do
            before do
              subject.register_parent node: :foo, class: ::StubEntity
            end

            it 'returns a node object' do
              result = subject.parent_node_for(:foo, ::StubEntity)

              expect(result).to be_a NodesReference::Node
              expect(result.name).to eql :foo
              expect(result.class_name).to eql ::StubEntity
            end
          end

          context "when node definition isn't present" do
            it 'raises Errors::NoParentNodeError' do
              expect {
                subject.parent_node_for(:foo, ::StubEntity)
              }.to raise_error(Errors::NoParentNodeError)
            end
          end
        end

        describe '#child_node_for parent_node, parent_class, child_class' do
          context 'when parent node definition is present' do
            before { subject.register_parent node: :foo, class: ::String }


            it 'returns all child_node definitions for determined arguments' do
              subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil })
              subject.register_child_node(:foo, String, { node: :fooza, class: ::StubEntity, cascade: true, foreign_key: nil })

              result = subject.child_node_for(:foo, ::String, ::StubEntity)

              result.each do |node|
                expect(node).to be_a NodesReference::Node
              end

              expect(result[0].name).to eql :stub_entity
              expect(result[0].class_name).to eql ::StubEntity
              expect(result[0].cascade).to be false
              expect(result[0].foreign_key).to be_nil
              expect(result[1].name).to eql :fooza
              expect(result[1].class_name).to eql ::StubEntity
              expect(result[1].cascade).to be true
              expect(result[1].foreign_key).to be_nil
            end

            it 'returns an empty array when no child_node definitions are found' do
              expect(
                subject.child_node_for(:foo, ::String, ::StubEntity)
              ).to be_empty
            end
          end

          context "when parent node definition isn't present" do
            it 'raises Errors::NoParentNodeError' do
              expect {
                subject.child_node_for(:foo, ::String, ::StubEntity)
              }.to raise_error(Errors::NoParentNodeError)
            end
          end
        end

        describe '#child_nodes_for parent_node, parent_class, child_class' do
          context 'when parent node definition is present' do
            before { subject.register_parent node: :foo, class: ::String }


            it 'returns all child_nodes definitions for determined arguments' do
              subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: false, foreign_key: nil })
              subject.register_child_nodes(:foo, String, { node: :foozas, class: ::StubEntity, cascade: true, foreign_key: nil })

              result = subject.child_nodes_for(:foo, ::String, ::StubEntity)

              result.each do |node|
                expect(node).to be_a NodesReference::Node
              end

              expect(result[0].name).to eql :stub_entities
              expect(result[0].class_name).to eql ::StubEntity
              expect(result[0].cascade).to be false
              expect(result[0].foreign_key).to be_nil
              expect(result[1].name).to eql :foozas
              expect(result[1].class_name).to eql ::StubEntity
              expect(result[1].cascade).to be true
              expect(result[1].foreign_key).to be_nil
            end

            it 'returns an empty array when no child_nodes definitions are found' do
              expect(
                subject.child_nodes_for(:foo, ::String, ::StubEntity)
              ).to be_empty
            end
          end

          context "when parent node definition isn't present" do
            it 'raises Errors::NoParentNodeError' do
              expect {
                subject.child_nodes_for(:foo, ::String, ::StubEntity)
              }.to raise_error(Errors::NoParentNodeError)
            end
          end
        end

        describe '#child_node_list_for parent_class' do
          it 'returns a collection of all child_node on parent' do
            subject.register_parent node: :foo, class: ::String
            subject.register_parent node: :bar, class: ::String

            subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil })
            subject.register_child_node(:foo, String, { node: :fooza, class: ::ParentEntity, cascade: false, foreign_key: nil })
            subject.register_child_node(:bar, String, { node: :child, class: ::StubEntity, cascade: false, foreign_key: :bar_id })

            expect(
              subject.child_node_list_for(String)
            ).to contain_exactly(:stub_entity, :fooza, :child)
          end

          it 'returns an empty array when no child is available for parent class' do
            subject.register_parent node: :foo, class: ::ParentEntity
            expect(subject.child_node_list_for(String)).to be_empty
            expect(subject.child_node_list_for(ParentEntity)).to be_empty
          end
        end

        describe '#child_nodes_list_for parent_class' do
          it 'returns a collection of all child_nodes on parent' do
            subject.register_parent node: :foo, class: ::String
            subject.register_parent node: :bar, class: ::String

            subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil })
            subject.register_child_nodes(:foo, String, { node: :foozas, class: ::ParentEntity, cascade: false, foreign_key: nil })
            subject.register_child_nodes(:bar, String, { node: :children, class: ::StubEntity, cascade: false, foreign_key: nil })

            expect(
              subject.child_nodes_list_for(String)
            ).to contain_exactly(:stub_entities, :foozas, :children)
          end

          it 'returns an empty array when no child is available for parent class' do
            subject.register_parent node: :foo, class: ::ParentEntity
            expect(subject.child_nodes_list_for(String)).to be_empty
            expect(subject.child_nodes_list_for(ParentEntity)).to be_empty
          end
        end

        describe '#cascading_child_node_list_for parent_class' do
          it 'returns a collection of all child_node on parent which have cascade as true' do
            subject.register_parent node: :foo, class: ::String

            subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil })
            subject.register_child_node(:foo, String, { node: :fooza, class: ::ParentEntity, cascade: false, foreign_key: nil })

            expect(
              subject.cascading_child_node_list_for(String)
            ).to contain_exactly(:stub_entity)
          end

          it 'returns an empty array when no cascading child is available' do
            subject.register_parent node: :foo, class: ::String

            subject.register_child_node(:foo, String, { node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil })
            subject.register_child_node(:foo, String, { node: :fooza, class: ::ParentEntity, cascade: false, foreign_key: nil })

            expect(subject.cascading_child_node_list_for(String)).to be_empty
          end

          it 'returns an empty array when no cascading child is available for parent class' do
            subject.register_parent node: :foo, class: ::ParentEntity

            subject.register_child_node(:foo, ParentEntity, { node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil })

            expect(subject.cascading_child_node_list_for(String)).to be_empty
          end

          it "returns an empty array when parent class isn't registered" do
            expect(subject.cascading_child_node_list_for(String)).to be_empty
          end
        end

        describe '#cascading_child_nodes_list_for parent_class' do
          it 'returns a collection of all child_nodes on parent which have cascade as true' do
            subject.register_parent node: :foo, class: ::String
            subject.register_parent node: :bar, class: ::String

            subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil })
            subject.register_child_nodes(:foo, String, { node: :foozas, class: ::ParentEntity, cascade: false, foreign_key: nil })
            subject.register_child_nodes(:bar, String, { node: :parents, class: ::ParentEntity, cascade: nil, foreign_key: :bar_id })

            expect(
              subject.cascading_child_nodes_list_for(String)
            ).to contain_exactly(:stub_entities)
          end

          it 'returns an empty array when no cascading child is available' do
            subject.register_parent node: :foo, class: ::String

            subject.register_child_nodes(:foo, String, { node: :stub_entities, class: ::StubEntity, cascade: false, foreign_key: nil })
            subject.register_child_nodes(:foo, String, { node: :foozas, class: ::ParentEntity, cascade: false, foreign_key: nil })

            expect(subject.cascading_child_nodes_list_for(String)).to be_empty
          end

          it 'returns an empty array when no cascading child is available for parent class' do
            subject.register_parent node: :foo, class: ::ParentEntity

            subject.register_child_nodes(:foo, ParentEntity, { node: :stub_entities, class: ::StubEntity, cascade: true, foreign_key: nil })

            expect(subject.cascading_child_nodes_list_for(String)).to be_empty
          end

          it "returns an empty array when parent class isn't registered" do
            expect(subject.cascading_child_nodes_list_for(String)).to be_empty
          end
        end
      end
    end
  end
end
