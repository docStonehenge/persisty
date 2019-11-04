require 'spec_helper'

module Persisty
  module Persistence
    module DocumentDefinitions
      describe DocumentCollectionBuilder do
        include_context 'StubEntity'

        let(:parent) { double(:entity) }
        let(:entity1) { ::StubEntity.new }
        let(:entity2) { ::StubEntity.new }
        let(:uow) { double(:uow) }

        subject { described_class.new(parent, proxy, ::StubEntity) }

        describe '#build_with entities, foreign_key' do
          before do
            DocumentCollectionFactory.collection_for(::StubEntity)
          end

          context "when entities collection isn't an array, nil or a valid DocumentCollection" do
            let(:proxy) { [] }

            before do
              DocumentCollectionFactory.collection_for(::StubEntityForCollection)
            end

            it 'raises ArgumentError' do
              expect {
                subject.build_with String.new, nil
              }.to raise_error(ArgumentError)

              expect {
                subject.build_with 123, :foo_id
              }.to raise_error(ArgumentError)

              expect {
                subject.build_with(
                  Associations::StubEntityForCollectionDocumentCollection.new(
                    double, ::StubEntityForCollection, []
                  ), nil
                )
              }.to raise_error(ArgumentError)
            end

            after do
              Associations.send(:remove_const, 'StubEntityForCollectionDocumentCollection')
            end
          end

          context 'when entities collection contain invalid values' do
            let(:entities) { [entity1, entity2] }

            context "when entities argument contain a nil value" do
              let(:proxy) { [] }

              it 'raises ArgumentError' do
                entities << nil

                expect {
                  subject.build_with entities, nil
                }.to raise_error(ArgumentError)
              end
            end

            context "when entities argument contain a number" do
              let(:proxy) { [] }

              it 'raises ArgumentError' do
                entities << 123

                expect {
                  subject.build_with entities, :foo_id
                }.to raise_error(ArgumentError)
              end
            end

            context "when entities argument contain an entity of another class" do
              let(:proxy) { [] }

              it 'raises ArgumentError' do
                entities << ::StubEntityForCollection.new

                expect {
                  subject.build_with entities
                }.to raise_error(ArgumentError)
              end
            end
          end

          context 'when collection is an array' do
            let(:entities) { [entity1, entity2] }

            context "when parent entity doesn't have a filled proxy yet" do
              let(:proxy) { [] }

              it 'returns a DocumentCollection filled with entities from array' do
                result = subject.build_with entities, nil

                expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                expect(result.all).to include(entity1, entity2)
              end
            end

            context 'when parent entity has a filled proxy' do
              context 'when proxy includes an entity from entities argument' do
                let(:proxy) { [entity1, ::StubEntity.new] }

                it "returns a DocumentCollection filled and doesn't mark entity as removed" do
                  expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow

                  expect(uow).not_to receive(:register_removed).with(entity1)
                  expect(uow).to receive(:register_removed).once.with(proxy[1])

                  result = subject.build_with entities, 'foo_id'

                  expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)

                  result_collection = result.all
                  expect(result_collection.size).to eql 2
                  expect(result_collection).to include(entity1, entity2)
                end
              end

              context "when proxy doesn't include any entity from entities argument" do
                let(:proxy) { [::StubEntity.new] }

                it "returns a DocumentCollection filled and doesn't mark entity as removed" do
                  expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow

                  expect(uow).to receive(:register_removed).once.with(proxy[0])

                  result = subject.build_with entities, :foo_id

                  expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)

                  result_collection = result.all
                  expect(result_collection.size).to eql 2
                  expect(result_collection).to include(entity1, entity2)
                end
              end
            end
          end

          context 'when collection is nil' do
            let(:entities) { nil }

            context "when parent entity doesn't have a filled proxy yet" do
              let(:proxy) { [] }

              it 'returns a DocumentCollection filled with a empty array' do
                result = subject.build_with entities, nil

                expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                expect(result.all).to be_empty
              end
            end

            context 'when parent entity has a filled proxy' do
              let(:proxy) { [entity1, ::StubEntity.new] }

              it "returns a DocumentCollection filled and marks all previous entities as removed" do
                expect(Persistence::UnitOfWork).to receive(:current).twice.and_return uow

                expect(uow).to receive(:register_removed).once.with(entity1)
                expect(uow).to receive(:register_removed).once.with(proxy[1])

                result = subject.build_with entities, :foo_id

                expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                expect(result.all).to be_empty
              end
            end
          end

          context 'when collection is a DocumentCollection for node class' do
            let(:entities) do
              Associations::StubEntityDocumentCollection.new(
                parent, ::StubEntity, nil, [entity1, entity2]
              )
            end

            context "when parent entity doesn't have a filled proxy yet" do
              let(:proxy) { [] }

              it 'returns a DocumentCollection filled with entities from array' do
                result = subject.build_with entities, :foo_id

                expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                expect(result).not_to equal entities
                expect(result.all).to include(entity1, entity2)
              end
            end

            context 'when parent entity has a filled proxy' do
              context 'when proxy includes an entity from entities argument' do
                let(:proxy) { [entity1, ::StubEntity.new] }

                it "returns a DocumentCollection filled and doesn't mark entity as removed" do
                  expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow

                  expect(uow).not_to receive(:register_removed).with(entity1)
                  expect(uow).to receive(:register_removed).once.with(proxy[1])

                  result = subject.build_with entities, 'foo_id'

                  expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)

                  result_collection = result.all
                  expect(result_collection.size).to eql 2
                  expect(result_collection).to include(entity1, entity2)
                end
              end

              context "when proxy doesn't include any entity from entities argument" do
                let(:proxy) { [::StubEntity.new] }

                it "returns a DocumentCollection filled and doesn't mark entity as removed" do
                  expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow

                  expect(uow).to receive(:register_removed).once.with(proxy[0])

                  result = subject.build_with entities, nil

                  expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)

                  result_collection = result.all
                  expect(result_collection.size).to eql 2
                  expect(result_collection).to include(entity1, entity2)
                end
              end
            end
          end

          after do
            Associations.send(:remove_const, 'StubEntityDocumentCollection')
          end
        end
      end
    end
  end
end
