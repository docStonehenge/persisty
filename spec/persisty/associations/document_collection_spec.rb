module Persisty
  module Associations
    describe DocumentCollection do
      include_context 'StubEntity'

      let(:parent) { double(:parent, id: BSON::ObjectId.new, class: String) }
      let(:repository) { double(:repository) }
      let(:uow) { double(:uow) }

      context 'when collection is nil' do
        subject { described_class.new(parent, StubEntity) }

        describe '#include entity' do
          before do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: parent.id }
                                  ).and_return collection
          end

          context 'when entity has id' do
            before do
              entity.id = BSON::ObjectId.new
            end

            context 'when entity is present on collection' do
              let(:collection) { [entity] }

              it 'returns true' do
                expect(subject.include?(entity)).to be true
              end
            end

            context "when entity isn't present on collection" do
              let(:collection) { [] }

              it 'returns false' do
                expect(subject.include?(entity)).to be false
              end
            end
          end

          context "when entity doesn't have id" do
            context 'when entity is present on collection' do
              let(:collection) { [entity, StubEntity.new] }

              it 'returns true' do
                expect(subject.include?(entity)).to be true
              end
            end

            context "when entity isn't present on collection" do
              let(:collection) { [StubEntity.new] }

              it 'returns false' do
                expect(subject.include?(entity)).to be false
              end
            end
          end
        end

        describe '#reload' do
          it 'clears collection variable, loads collection and returns subject' do
            expect(Persistence::UnitOfWork).not_to receive(:current)

            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: parent.id }
                                  ).and_return [entity]

            expect(subject.reload).to eql subject
          end
        end

        describe '#remove entity' do
          let(:other_entity) { StubEntity.new }

          context "when entity isn't of document class" do
            it 'raises ArgumentError' do
              expect {
                subject.remove(StubEntityForCollection.new)
              }.to raise_error(ArgumentError)
            end
          end

          context 'when entity is of document class' do
            before do
              expect(
                Repositories::Registry
              ).to receive(:[]).once.with(StubEntity).and_return repository

              expect(repository).to receive(:find_all).once.with(
                                      filter: { string_id: parent.id }
                                    ).and_return collection
            end

            context 'when collection includes entity to be removed' do
              let(:collection) { [other_entity] }

              context 'when entity has foreign key equal to collection parent' do
                before do
                  allow(other_entity).to receive(:string_id).and_return parent.id
                end

                it 'removes from collection and calls UnitOfWork to remove entity' do
                  expect(
                    Persistence::UnitOfWork
                  ).to receive(:current).once.and_return uow

                  expect(uow).to receive(:register_removed).once.with(other_entity)

                  subject.remove other_entity

                  expect(collection).not_to include other_entity
                end
              end

              context 'when entity has nil foreign key' do
                before do
                  allow(other_entity).to receive(:string_id).and_return nil
                end

                it 'removes from collection and calls UnitOfWork to remove entity' do
                  expect(
                    Persistence::UnitOfWork
                  ).to receive(:current).once.and_return uow

                  expect(uow).to receive(:register_removed).once.with(other_entity)

                  subject.remove other_entity

                  expect(collection).not_to include other_entity
                end
              end

              context 'when entity has foreign key different from parent' do
                before do
                  allow(other_entity).to receive(:string_id).and_return 123
                end

                it "removes from collection but doesn't call UnitOfWork to remove entity" do
                  expect(Persistence::UnitOfWork).not_to receive(:current)

                  subject.remove other_entity

                  expect(collection).not_to include other_entity
                end
              end
            end

            context "when collection doesn't include entity" do
              let(:collection) { [] }

              it 'halts execution' do
                expect {
                  expect(other_entity).not_to receive(:string_id)
                  expect(Persistence::UnitOfWork).not_to receive(:current)

                  subject.remove other_entity
                }.not_to change(collection, :size)
              end
            end
          end
        end

        describe '#<< entity' do
          let(:other_entity) { StubEntity.new }

          context "when argument isn't of collection class" do
            let(:collection) { [entity] }

            it 'raises ArgumentError' do
              expect {
                subject << StubEntityForCollection.new
              }.to raise_error(ArgumentError)
            end
          end

          context 'when argument is of collection class' do
            before do
              expect(
                Repositories::Registry
              ).to receive(:[]).once.with(StubEntity).and_return repository

              expect(repository).to receive(:find_all).once.with(
                                      filter: { string_id: parent.id }
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

              it 'pushes entity to collection' do
                subject << other_entity
                expect(collection).to eql([other_entity, entity])
              end
            end
          end
        end

        describe '#push entity' do
          let(:other_entity) { StubEntity.new }

          context "when argument isn't of collection class" do
            let(:collection) { [entity] }

            it 'raises ArgumentError' do
              expect {
                subject.push StubEntityForCollection.new
              }.to raise_error(ArgumentError)
            end
          end

          context 'when argument is of collection class' do
            before do
              expect(
                Repositories::Registry
              ).to receive(:[]).once.with(StubEntity).and_return repository

              expect(repository).to receive(:find_all).once.with(
                                      filter: { string_id: parent.id }
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

              it 'pushes entity to collection' do
                subject.push other_entity
                expect(collection).to eql([other_entity, entity])
              end
            end
          end
        end

        describe '#all' do
          it 'calls repository to load collection and returns all objects found' do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: parent.id }
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
                                    filter: { string_id: parent.id }
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
                                    filter: { string_id: parent.id }
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
                                    filter: { string_id: parent.id }, limit: 1
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
                                    filter: { string_id: parent.id },
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
                                    filter: { string_id: parent.id }
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
                                    filter: { string_id: parent.id }
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
                                    filter: { string_id: parent.id }
                                  ).and_return [entity]

            expect(subject.count).to eql 1
          end
        end
      end

      context "when collection isn't nil" do
        let(:collection) { [entity] }

        subject { described_class.new(parent, StubEntity, collection) }

        describe '#include entity' do
          before do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
          end

          context 'when entity has id' do
            before do
              entity.id = BSON::ObjectId.new
            end

            context 'when entity is present on collection' do
              let(:collection) { [entity] }

              it 'returns true' do
                expect(subject.include?(entity)).to be true
              end
            end

            context "when entity isn't present on collection" do
              let(:collection) { [] }

              it 'returns false' do
                expect(subject.include?(entity)).to be false
              end
            end
          end

          context "when entity doesn't have id" do
            context 'when entity is present on collection' do
              let(:collection) { [entity, StubEntity.new] }

              it 'returns true' do
                expect(subject.include?(entity)).to be true
              end
            end

            context "when entity isn't present on collection" do
              let(:collection) { [StubEntity.new] }

              it 'returns false' do
                expect(subject.include?(entity)).to be false
              end
            end
          end
        end

        describe '#reload' do
          it 'detaches entities, clears collection variable, loads collection and returns subject' do
            expect(
              Persistence::UnitOfWork
            ).to receive(:current).once.and_return uow

            expect(uow).to receive(:detach).once.with(entity)

            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(StubEntity).and_return repository

            expect(repository).to receive(:find_all).once.with(
                                    filter: { string_id: parent.id }
                                  ).and_return [entity]

            expect(subject.reload).to eql subject
          end
        end

        describe '#remove entity' do
          let(:other_entity) { StubEntity.new }

          before do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
          end

          context "when entity isn't of document class" do
            it 'raises ArgumentError' do
              expect {
                subject.remove(StubEntityForCollection.new)
              }.to raise_error(ArgumentError)
            end
          end

          context 'when collection includes entity to be removed' do
            let(:collection) { [other_entity] }

            context 'when entity has foreign key equal to collection parent' do
              before do
                allow(other_entity).to receive(:string_id).and_return parent.id
              end

              it 'removes from collection and calls UnitOfWork to remove entity' do
                expect(
                  Persistence::UnitOfWork
                ).to receive(:current).once.and_return uow

                expect(uow).to receive(:register_removed).once.with(other_entity)

                subject.remove other_entity

                expect(collection).not_to include other_entity
              end
            end

            context 'when entity has nil foreign key' do
              before do
                allow(other_entity).to receive(:string_id).and_return nil
              end

              it 'removes from collection and calls UnitOfWork to remove entity' do
                expect(
                  Persistence::UnitOfWork
                ).to receive(:current).once.and_return uow

                expect(uow).to receive(:register_removed).once.with(other_entity)

                subject.remove other_entity

                expect(collection).not_to include other_entity
              end
            end

            context 'when entity has foreign key different from parent' do
              before do
                allow(other_entity).to receive(:string_id).and_return 123
              end

              it "removes from collection but doesn't call UnitOfWork to remove entity" do
                expect(Persistence::UnitOfWork).not_to receive(:current)

                subject.remove other_entity

                expect(collection).not_to include other_entity
              end
            end
          end

          context "when collection doesn't include entity" do
            let(:collection) { [] }

            it 'halts execution' do
              expect {
                expect(other_entity).not_to receive(:string_id)
                expect(Persistence::UnitOfWork).not_to receive(:current)

                subject.remove other_entity
              }.not_to change(collection, :size)
            end
          end
        end

        describe '#<< entity' do
          let(:other_entity) { StubEntity.new }

          before do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
          end

          context "when argument isn't of collection class" do
            let(:collection) { [entity] }

            it 'raises ArgumentError' do
              expect {
                subject << StubEntityForCollection.new
              }.to raise_error(ArgumentError)
            end
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

              subject { described_class.new(parent, StubEntity, collection) }

              it 'skips pushing and sorting on collection' do
                subject << other_entity

                expect(collection.count).to eql 2
                expect(collection).to eql([other_entity, entity])
              end
            end
          end

          context "when entity doesn't have ID" do
            it 'pushes entity to collection' do
              entity.id = BSON::ObjectId.new

              subject << other_entity
              expect(collection).to eql([other_entity, entity])
            end

            context "when all entities on collection doesn't have ID" do
              it 'pushes entity to collection' do
                subject << other_entity
                expect(collection).to eql([other_entity, entity])
              end
            end
          end
        end

        describe '#push entity' do
          let(:other_entity) { StubEntity.new }

          before do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
          end

          context "when argument isn't of collection class" do
            let(:collection) { [entity] }

            it 'raises ArgumentError' do
              expect {
                subject.push StubEntityForCollection.new
              }.to raise_error(ArgumentError)
            end
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

              subject { described_class.new(parent, StubEntity, collection) }

              it 'skips pushing and sorting on collection' do
                subject.push other_entity

                expect(collection.count).to eql 2
                expect(collection).to eql([other_entity, entity])
              end
            end
          end

          context "when entity doesn't have ID" do
            it 'pushes entity to collection' do
              entity.id = BSON::ObjectId.new

              subject.push other_entity
              expect(collection).to eql([other_entity, entity])
            end

            context "when all entities on collection doesn't have ID" do
              it 'pushes entity to collection' do
                subject << other_entity
                expect(collection).to eql([other_entity, entity])
              end
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
          subject { described_class.new(parent, StubEntity, [entity, double]) }

          it 'returns object on index' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject[0]).to eql entity
          end
        end

        describe '#first' do
          subject { described_class.new(parent, StubEntity, [entity, double]) }

          it 'returns first object on collection' do
            expect(Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(subject.first).to eql entity
          end
        end

        describe '#last' do
          subject { described_class.new(parent, StubEntity, [entity, last_entity]) }

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
