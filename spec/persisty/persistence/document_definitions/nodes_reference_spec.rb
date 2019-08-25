module Persisty
  module Persistence
    module DocumentDefinitions
      describe NodesReference do
        include_context 'StubEntity'

        describe 'register kind, node_definition' do
          it 'registers node definition correctly on child_node' do
            subject.register :child_node, foo: { type: ::StubEntity, cascade: false }

            expect(
              subject.instance_variable_get(:@nodes)
            ).to include(child_node: { foo: { type: ::StubEntity, cascade: false } })
          end

          it 'registers node definition correctly on child_nodes' do
            subject.register :child_nodes, foo: { type: ::StubEntity, cascade: false }

            expect(
              subject.instance_variable_get(:@nodes)
            ).to include(child_nodes: { foo: { type: ::StubEntity, cascade: false } })
          end

          it 'registers node definition correctly on parent_node' do
            subject.register :parent_node, foo: { type: ::StubEntity, cascade: false }

            expect(
              subject.instance_variable_get(:@nodes)
            ).to include(parent_node: { foo: { type: ::StubEntity, cascade: false } })
          end

          it 'raises error when kind is invalid' do
            expect {
              subject.register :parent, foo: { type: ::StubEntity, cascade: false }
            }.to raise_error(NodesReference::InvalidNodeKind, 'invalid node kind')
          end

          context 'when node_definition is invalid' do
            it "raises error when type key isn't present" do
              expect {
                subject.register :parent_node, foo: { kind: ::StubEntity, cascade: false }
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :type')
            end

            it "raises error when cascade key isn't present" do
              expect {
                subject.register :parent_node, foo: { type: ::StubEntity, foo: :bar }
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition: key not found: :cascade')
            end

            it "raises error when node definition doesn't have size of two" do
              expect {
                subject.register :parent_node, foo: { type: ::StubEntity }
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')

              expect {
                subject.register :parent_node, foo: { type: ::StubEntity, cascade: false, foo: :bar }
              }.to raise_error(NodesReference::InvalidNodeDefinition, 'invalid node definition')
            end
          end
        end

        describe '#parent_nodes_list' do
          it 'returns an array with all parent_node keys' do
            subject.register :parent_node, post: { type: ::StubEntity, cascade: false }
            subject.register :parent_node, author: { type: ::StubEntity, cascade: false }

            expect(subject.parent_nodes_list).to eql [:post, :author]
          end
        end

        describe '#parent_nodes_map' do
          it 'returns the hash with all parent_node definitions' do
            subject.register :parent_node, post: { type: ::StubEntity, cascade: false }
            subject.register :parent_node, author: { type: ::StubEntity, cascade: false }

            expect(
              subject.parent_nodes_map
            ).to eql(
                   post: { type: ::StubEntity, cascade: false },
                   author: { type: ::StubEntity, cascade: false }
                 )
          end
        end

        describe '#child_nodes_list' do
          it 'returns an array with all child_node keys' do
            subject.register :child_node, child: { type: ::StubEntity, cascade: false }

            expect(subject.child_nodes_list).to eql [:child]
          end
        end

        describe '#child_nodes_map' do
          it 'returns the hash with all child_node definitions' do
            subject.register :child_node, child: { type: ::StubEntity, cascade: false }

            expect(
              subject.child_nodes_map
            ).to eql(child: { type: ::StubEntity, cascade: false })
          end
        end

        describe '#child_nodes_collections_list' do
          it 'returns an array with all child_nodes keys' do
            subject.register :child_nodes, posts: { type: ::StubEntity, cascade: false }

            expect(subject.child_nodes_collections_list).to eql [:posts]
          end
        end

        describe '#child_nodes_collections_map' do
          it 'returns the hash with all child_nodes definitions' do
            subject.register :child_nodes, posts: { type: ::StubEntity, cascade: false }

            expect(
              subject.child_nodes_collections_map
            ).to eql(posts: { type: ::StubEntity, cascade: false })
          end
        end
      end
    end
  end
end
