module Persisty
  module Associations
    describe DocumentCollection do
      include_context 'StubEntity'

      let(:model) { double(:model, id: BSON::ObjectId.new, class: String) }
      let(:document_manager) { double(:document_manager) }

      context 'when collection is nil' do
        subject { described_class.new(model, StubEntity) }

        describe '#all' do
          it 'calls repository to load collection and returns all objects found' do
            expect(
              DocumentManager
            ).to receive(:new).once.and_return document_manager

            expect(document_manager).to receive(:find_all).once.with(
                                          StubEntity, filter: { string_id: model.id }
                                        ).and_return [entity]

            expect(subject.all).to eql [entity]
          end
        end

        describe '#each' do
          it 'calls repository to load collection and yields each object loaded' do
            expect(
              DocumentManager
            ).to receive(:new).once.and_return document_manager

            expect(document_manager).to receive(:find_all).once.with(
                                          StubEntity, filter: { string_id: model.id }
                                        ).and_return [entity]

            expect { |b| subject.each(&b) }.to yield_with_args(entity)
          end
        end

        describe '#[] index' do
          it 'calls repository to load collection and returns object on index' do
            expect(
              DocumentManager
            ).to receive(:new).once.and_return document_manager

            expect(document_manager).to receive(:find_all).once.with(
                                          StubEntity, filter: { string_id: model.id }
                                        ).and_return [entity, double]

            expect(subject[0]).to eql entity
          end
        end

        describe '#first' do
          it 'calls repository to load collection and returns first object' do
            expect(
              DocumentManager
            ).to receive(:new).once.and_return document_manager

            expect(document_manager).to receive(:find_all).once.with(
                                          StubEntity, filter: { string_id: model.id }
                                        ).and_return [entity, double]

            expect(subject.first).to eql entity
          end
        end

        describe '#last' do
          let(:last_entity) { double }

          it 'calls repository to load collection and returns last object' do
            expect(
              DocumentManager
            ).to receive(:new).once.and_return document_manager

            expect(document_manager).to receive(:find_all).once.with(
                                          StubEntity, filter: { string_id: model.id }
                                        ).and_return [entity, last_entity]

            expect(subject.last).to eql last_entity
          end
        end
      end

      context "when collection isn't nil" do
        subject { described_class.new(model, StubEntity, [entity]) }

        describe '#all' do
          it 'returns collection without trying to load objects' do
            expect(DocumentManager).not_to receive(:new)
            expect(subject.all).to eql [entity]
          end
        end

        describe '#each' do
          it 'yields each object from already loaded collection' do
            expect(DocumentManager).not_to receive(:new)
            expect { |b| subject.each(&b) }.to yield_with_args(entity)
          end
        end

        describe '#[] index' do
          subject { described_class.new(model, StubEntity, [entity, double]) }

          it 'returns object on index' do
            expect(DocumentManager).not_to receive(:new)
            expect(subject[0]).to eql entity
          end
        end

        describe '#first' do
          subject { described_class.new(model, StubEntity, [entity, double]) }

          it 'returns first object on collection' do
            expect(DocumentManager).not_to receive(:new)
            expect(subject.first).to eql entity
          end
        end

        describe '#last' do
          subject { described_class.new(model, StubEntity, [entity, last_entity]) }

          let(:last_entity) { double }

          it 'returns last object on collection' do
            expect(DocumentManager).not_to receive(:new)
            expect(subject.last).to eql last_entity
          end
        end
      end
    end
  end
end
