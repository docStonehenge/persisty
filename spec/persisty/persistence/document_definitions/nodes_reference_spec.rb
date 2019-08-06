module Persisty
  module Persistence
    module DocumentDefinitions
      describe NodesReference do
        include_context 'StubEntity'

        describe 'register kind, node_definition' do
          it 'registers node definition correctly on child_node' do
            subject.register :child_node, foo: { type: ::StubEntity, cascade: false }

            expect(
              subject.nodes
            ).to include(child_node: { foo: { type: ::StubEntity, cascade: false } })
          end

          it 'registers node definition correctly on child_nodes' do
            subject.register :child_nodes, foo: { type: ::StubEntity, cascade: false }

            expect(
              subject.nodes
            ).to include(child_nodes: { foo: { type: ::StubEntity, cascade: false } })
          end

          it 'registers node definition correctly on parent_node' do
            subject.register :parent_node, foo: { type: ::StubEntity, cascade: false }

            expect(
              subject.nodes
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
      end
    end
  end
end
