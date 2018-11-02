module Persisty
  module Associations
    describe DocumentCollection do
      include_context 'StubEntity'

      let(:model) { double(:model, id: BSON::ObjectId.new, class: String) }
      let(:repository) { double(:repository) }

      context 'when collection is nil' do
        subject { described_class.new(model, StubEntity) }

        describe '#reload' do
          it 'clears collection variable, loads collection and returns subject' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity]

            expect(subject.reload).to eql subject
          end
        end

        describe '#<< entity' do
          let(:other_entity) { StubEntity.new }

          before do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return collection
          end

          context 'when entity has ID' do
            before do
              other_entity.id = BSON::ObjectId.new
              entity.id = BSON::ObjectId.new
            end

            context "when collection doesn't include entity yet" do
              let(:collection) { [entity] }

              it 'pushes entity to collection, sorting collection after' do
                subject << other_entity

                expect(collection).to eql([other_entity, entity])
              end
            end

            context 'when collection already include entity' do
              let(:collection) { [other_entity, entity] }

              it 'skips pushing and sorting on collection' do
                subject << other_entity

                expect(collection.count).to eql 2
                expect(collection).to eql([other_entity, entity])
              end
            end
          end

          context "when entity doesn't have ID" do
            before { entity.id = BSON::ObjectId.new }

            let(:collection) { [entity] }

            it 'pushes entity to collection, leaving pushed entity in last' do
              subject << other_entity
              expect(collection).to eql([entity, other_entity])
            end
          end
        end

        describe '#push entity' do
          let(:other_entity) { StubEntity.new }

          before do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return collection
          end

          context 'when entity has ID' do
            before do
              other_entity.id = BSON::ObjectId.new
              entity.id = BSON::ObjectId.new
            end

            context "when collection doesn't include entity yet" do
              let(:collection) { [entity] }

              it 'pushes entity to collection, sorting collection after' do
                subject.push other_entity

                expect(collection).to eql([other_entity, entity])
              end
            end

            context 'when collection already include entity' do
              let(:collection) { [other_entity, entity] }

              it 'skips pushing and sorting on collection' do
                subject.push other_entity

                expect(collection.count).to eql 2
                expect(collection).to eql([other_entity, entity])
              end
            end
          end

          context "when entity doesn't have ID" do
            before { entity.id = BSON::ObjectId.new }

            let(:collection) { [entity] }

            it 'pushes entity to collection, leaving pushed entity in last' do
              subject.push other_entity
              expect(collection).to eql([entity, other_entity])
            end
          end
        end

        describe '#all' do
          it 'calls repository to load collection and returns all objects found' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity]

            expect(subject.all).to eql [entity]
          end
        end

        describe '#each' do
          it 'calls repository to load collection and yields each object loaded' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity]

            expect { |b| subject.each(&b) }.to yield_with_args(entity)
          end
        end

        describe '#[] index' do
          it 'calls repository to load collection and returns object on index' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity, double]

            expect(subject[0]).to eql entity
          end
        end

        describe '#first' do
          it 'calls repository to find entities limiting at one and returns first object' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }, limit: 1
                                  ).and_return [entity]

            expect(subject.first).to eql entity
          end
        end

        describe '#last' do
          let(:last_entity) { double }

          it 'calls repository to return entity limiting at one and sorting ID descending' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id },
                                    sort: { _id: -1 }, limit: 1
                                  ).and_return [last_entity]

            expect(subject.last).to eql last_entity
          end
        end

        describe '#_as_mongo_document' do
          let(:entity_document) { entity._as_mongo_document }

          it 'calls repository to load collection and transforms each object to mongo_document' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity]

            expect(subject._as_mongo_document).to include entity_document
          end
        end

        describe '#size' do
          it 'calls repository to load collection and returns collection size' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity]

            expect(subject.size).to eql 1
          end
        end

        describe '#count' do
          it 'calls repository to load collection and returns collection count' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity]

            expect(subject.count).to eql 1
          end
        end
      end

      context "when collection isn't nil" do
        let(:collection) { [entity] }

        subject { described_class.new(model, StubEntity, collection) }

        describe '#reload' do
          it 'clears collection variable, loads collection and returns subject' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: model.id }
                                  ).and_return [entity]

            expect(subject.reload).to eql subject
          end
        end

        describe '#<< entity' do
          let(:other_entity) { StubEntity.new }

          before do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
          end

          context 'when entity has ID' do
            before do
              other_entity.id = BSON::ObjectId.new
              entity.id = BSON::ObjectId.new
            end

            context "when collection doesn't include entity yet" do
              it 'pushes entity to collection, sorting collection after' do
                subject << other_entity

                expect(collection).to eql([other_entity, entity])
              end
            end

            context 'when collection already include entity' do
              let(:collection) { [other_entity, entity] }

              subject { described_class.new(model, StubEntity, collection) }

              it 'skips pushing and sorting on collection' do
                subject << other_entity

                expect(collection.count).to eql 2
                expect(collection).to eql([other_entity, entity])
              end
            end
          end

          context "when entity doesn't have ID" do
            before { entity.id = BSON::ObjectId.new }

            it 'pushes entity to collection, leaving pushed entity in last' do
              subject << other_entity
              expect(collection).to eql([entity, other_entity])
            end
          end
        end

        describe '#push entity' do
          let(:other_entity) { StubEntity.new }

          before do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
          end

          context 'when entity has ID' do
            before do
              other_entity.id = BSON::ObjectId.new
              entity.id = BSON::ObjectId.new
            end

            context "when collection doesn't include entity yet" do
              it 'pushes entity to collection, sorting collection after' do
                subject.push other_entity

                expect(collection).to eql([other_entity, entity])
              end
            end

            context 'when collection already include entity' do
              let(:collection) { [other_entity, entity] }

              subject { described_class.new(model, StubEntity, collection) }

              it 'skips pushing and sorting on collection' do
                subject.push other_entity

                expect(collection.count).to eql 2
                expect(collection).to eql([other_entity, entity])
              end
            end
          end

          context "when entity doesn't have ID" do
            before { entity.id = BSON::ObjectId.new }

            it 'pushes entity to collection, leaving pushed entity in last' do
              subject.push other_entity
              expect(collection).to eql([entity, other_entity])
            end
          end
        end

        describe '#all' do
          it 'returns collection without trying to load objects' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject.all).to eql [entity]
          end
        end

        describe '#each' do
          it 'yields each object from already loaded collection' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect { |b| subject.each(&b) }.to yield_with_args(entity)
          end
        end

        describe '#[] index' do
          subject { described_class.new(model, StubEntity, [entity, double]) }

          it 'returns object on index' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject[0]).to eql entity
          end
        end

        describe '#first' do
          subject { described_class.new(model, StubEntity, [entity, double]) }

          it 'returns first object on collection' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject.first).to eql entity
          end
        end

        describe '#last' do
          subject { described_class.new(model, StubEntity, [entity, last_entity]) }

          let(:last_entity) { double }

          it 'returns last object on collection' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject.last).to eql last_entity
          end
        end

        describe '#_as_mongo_document' do
          let(:entity_document) { entity._as_mongo_document }

          it 'transforms each object to mongo_document' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject._as_mongo_document).to include entity_document
          end
        end

        describe '#size' do
          it 'returns collection size' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject.size).to eql 1
          end
        end

        describe '#count' do
          it 'returns collection count' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject.count).to eql 1
          end
        end
      end
    end
  end
end
