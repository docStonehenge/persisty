module Persisty
  module Persistence
    module DocumentDefinitions
      module NodeAssignments
        describe CheckObjectType do
          include_context 'StubEntity'

          describe '.call node_class, node_name, object' do
            context 'when object is nil' do
              it 'halts execution' do
                expect(described_class.(StubEntity, :stub_entity, nil)).to be_nil
              end
            end

            context 'when object is an instance of node class' do
              it 'halts execution' do
                expect(described_class.(StubEntity, :stub_entity, entity)).to be_nil
              end
            end

            context "when object is present but isn't an instance of node_class" do
              it 'raises TypeError with message for type mismatch' do
                expect {
                  described_class.(StubEntity, :stub_entity, String.new)
                }.to raise_error(TypeError, "Object is a type mismatch from defined node 'stub_entity'")
              end
            end
          end
        end
      end
    end
  end
end
