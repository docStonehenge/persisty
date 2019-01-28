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

        subject { described_class.new(parent, :stub_entities, ::StubEntity) }

        describe '#build_collection entities' do
          before do
            DocumentCollectionFactory.collection_for(::StubEntity)
          end

          context 'when collection is an array' do
            let(:entities) { [entity1, entity2] }

            context "when parent entity doesn't have a filled proxy yet" do
              before do
                expect(parent).to receive(:stub_entities).once.and_return []
              end

              it 'returns a DocumentCollection filled with entities from array' do
                result = subject.build_collection entities

                expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                expect(result.all).to include(entity1, entity2)
              end
            end

            context 'when parent entity has a filled proxy' do
              before do
                expect(parent).to receive(:stub_entities).once.and_return proxy
              end

              context 'when proxy includes an entity from entities argument' do
                let(:proxy) { [entity1, ::StubEntity.new] }

                it "returns a DocumentCollection filled and doesn't mark entity as removed" do
                  expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow

                  expect(uow).not_to receive(:register_removed).with(entity1)
                  expect(uow).to receive(:register_removed).once.with(proxy[1])

                  result = subject.build_collection entities

                  expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                  expect(result.all).to include(entity1, entity2)
                end
              end

              context "when proxy doesn't include any entity from entities argument" do
                let(:proxy) { [::StubEntity.new] }

                it "returns a DocumentCollection filled and doesn't mark entity as removed" do
                  expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow

                  expect(uow).to receive(:register_removed).once.with(proxy[0])

                  result = subject.build_collection entities

                  expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                  expect(result.all).to include(entity1, entity2)
                end
              end
            end
          end

          context 'when collection is nil' do
            let(:entities) { nil }

            context "when parent entity doesn't have a filled proxy yet" do
              before do
                expect(parent).to receive(:stub_entities).once.and_return []
              end

              it 'returns a DocumentCollection filled with a empty array' do
                result = subject.build_collection entities

                expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                expect(result.all).to be_empty
              end
            end

            context 'when parent entity has a filled proxy' do
              let(:proxy) { [entity1, ::StubEntity.new] }

              before do
                expect(parent).to receive(:stub_entities).once.and_return proxy
              end

              it "returns a DocumentCollection filled and marks all previous entities as removed" do
                expect(Persistence::UnitOfWork).to receive(:current).twice.and_return uow

                expect(uow).to receive(:register_removed).once.with(entity1)
                expect(uow).to receive(:register_removed).once.with(proxy[1])

                result = subject.build_collection entities

                expect(result).to be_an_instance_of(Associations::StubEntityDocumentCollection)
                expect(result.all).to be_empty
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
