require 'spec_helper'

module Persisty
  module Persistence
    module DocumentDefinitions
      describe DocumentCollectionFactory do
        describe '.collection_for entity_class' do
          before do
            Object.const_set('Test', Class.new)
            Associations.const_set('TestDocumentCollection', Class.new)
          end

          context 'when collection class exists' do
            it 'returns collection class' do
              expect(
                described_class.collection_for(Test)
              ).to eql Associations::TestDocumentCollection
            end
          end

          context "when collection class doesn't exist yet" do
            before do
              Associations.send(:remove_const, 'TestDocumentCollection')
            end

            it 'returns collection class' do
              expect(
                described_class.collection_for(Test)
              ).to eql Associations::TestDocumentCollection

              expect(
                Associations::TestDocumentCollection
              ).to be < Associations::DocumentCollection
            end
          end
        end

        after do
          Object.send(:remove_const, 'Test')
          Associations.send(:remove_const, 'TestDocumentCollection')
        end
      end
    end
  end
end
