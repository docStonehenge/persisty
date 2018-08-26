module Persisty
  module Repositories
    describe Base do
      include_context 'StubEntity'
      include_context 'StubRepository'

      let(:client) { double(:client) }
      let(:uow) { double(:uow) }
      let(:entity) { double(:entity, id: 1) }
      let(:entity2) { double(:entity, id: 2) }
      let(:entity_to_save) { ::StubEntity.new(id: BSON::ObjectId.new) }

      let(:described_class) { ::StubRepository }

      subject { described_class.new(client: client) }

      describe 'attributes' do
        specify do
          expect(subject.instance_variable_get(:@connection)).to eql client
        end
      end

      describe '#find id' do
        context 'when no UnitOfWork is set on current Thread' do
          it 'raises error on call to get loaded entities' do
            expect(
              Persistence::UnitOfWork
            ).to receive(:current).and_raise Persistence::UnitOfWorkNotStartedError

            expect {
              subject.find('123')
            }.to raise_error(Persistence::UnitOfWorkNotStartedError)
          end
        end

        context 'when entity is not yet loaded on registry' do
          before do
            allow(Persistence::UnitOfWork).to receive(:current).and_return uow
            allow(uow).to receive(:get).once.with(::StubEntity, '123').and_return nil
          end

          it 'queries for entity with id, sets into current uow and returns entity object' do
            expect(client).to receive(:find_on).once.with(
                                :stub_entities, filter: { _id: '123' }, sort: {}
                              ).and_return [{ '_id' => '123' }]

            expect(::StubEntity).to receive(:new).once.with(
                                          '_id' => '123'
                                        ).and_return entity

            expect(uow).to receive(:track_clean).once.with(entity).and_return entity

            expect(subject.find('123')).to eql entity
          end
        end

        context 'when entity is already loaded on registry' do
          before do
            allow(Persistence::UnitOfWork).to receive(:current).and_return uow
            allow(uow).to receive(:get).once.with(::StubEntity, '123').and_return entity
          end

          it 'returns entity got from uow clean entities list' do
            expect(client).not_to receive(:find_on).with(any_args)
            expect(::StubEntity).not_to receive(:new).with(any_args)
            expect(subject.find('123')).to eql entity
          end
        end

        context 'when entity ID is not found' do
          it 'raises EntityNotFoundError' do
            allow(Persistence::UnitOfWork).to receive(:current).and_return uow
            allow(uow).to receive(:get).once.with(::StubEntity, '123').and_return nil

            expect(client).to receive(:find_on).once.with(
                                :stub_entities, filter: { _id: '123' }, sort: {}
                              ).and_return []

            expect { subject.find('123') }.to raise_error(
                                                EntityNotFoundError,
                                                'Unable to find StubEntity with ID #123'
                                              )
          end
        end
      end

      describe '#find_all filter: {}, sorted_by: {}' do
        it 'raises error when call to current UnitOfWork raises error' do
          expect(client).to receive(:find_on).with(
                              :stub_entities, filter: {}, sort: {}
                            ).and_return(
                              [{ '_id' => 1 }]
                            )

          expect(
            Persistence::UnitOfWork
          ).to receive(:current).and_raise Persistence::UnitOfWorkNotStartedError

          expect {
            subject.find_all
          }.to raise_error(Persistence::UnitOfWorkNotStartedError)
        end

        context 'when UnitOfWork has no clean objects loaded' do
          before do
            allow(Persistence::UnitOfWork).to receive(:current).and_return uow
          end

          context 'when provided with a query filter' do
            before do
              expect(client).to receive(:find_on).once.with(
                                  :stub_entities, filter: { period: Date.parse('January/2016') }, sort: {}
                                ).and_return [{ '_id' => 1 }]

              expect(uow).to receive(:get).once.with(::StubEntity, 1).and_return nil
            end

            it 'returns a set of entity objects found on database' do
              expect(::StubEntity).to receive(:new).once.with(
                                            '_id' => 1
                                          ).and_return entity

              expect(uow).to receive(:track_clean).once.with(entity).and_return entity

              expect(
                subject.find_all(filter: { period: Date.parse('January/2016') })
              ).to eql [entity]
            end
          end

          context 'when not provided with a query filter' do
            before do
              expect(client).to receive(:find_on).with(
                                  :stub_entities, filter: {}, sort: {}
                                ).and_return(
                                  [
                                    { '_id' => 1 },
                                    { '_id' => 2 }
                                  ]
                                )

              expect(uow).to receive(:get).once.with(::StubEntity, 1).and_return nil
              expect(uow).to receive(:get).once.with(::StubEntity, 2).and_return nil
            end

            it 'returns all documents as entity objects' do
              expect(::StubEntity).to receive(:new).once.with(
                                            { '_id' => 1 }
                                          ).and_return entity

              expect(::StubEntity).to receive(:new).once.with(
                                            { '_id' => 2 }
                                          ).and_return entity2

              expect(uow).to receive(:track_clean).once.with(entity).and_return entity
              expect(uow).to receive(:track_clean).once.with(entity2).and_return entity2

              expect(subject.find_all).to eql [entity, entity2]
            end
          end

          context 'when provided with a sorted_by option' do
            before do
              expect(uow).to receive(:get).once.with(::StubEntity, 1).and_return nil
              expect(uow).to receive(:get).once.with(::StubEntity, 2).and_return nil

              expect(client).to receive(:find_on).with(
                                  :stub_entities, filter: {}, sort: { period: 1 }
                                ).and_return(
                                  [
                                    { '_id' => 2 },
                                    { '_id' => 1 }
                                  ]
                                )
            end

            it 'returns all documents sorted as entity objects' do
              expect(::StubEntity).to receive(:new).once.with(
                                            { '_id' => 2 }
                                          ).and_return entity2

              expect(::StubEntity).to receive(:new).once.with(
                                            { '_id' => 1 }
                                          ).and_return entity

              expect(uow).to receive(:track_clean).once.with(entity2).and_return entity2
              expect(uow).to receive(:track_clean).once.with(entity).and_return entity

              expect(subject.find_all(sorted_by: { period: 1 })).to eql [entity2, entity]
            end
          end
        end

        context 'when UnitOfWork contains clean entities instances loaded' do
          before do
            allow(Persistence::UnitOfWork).to receive(:current).and_return uow

            @loaded_entity = ::StubEntity.new

            expect(uow).to receive(
                             :get
                           ).once.with(::StubEntity, 124).and_return @loaded_entity

            expect(uow).to receive(
                             :get
                           ).once.with(::StubEntity, 125).and_return nil
          end

          context 'when provided with a query filter' do
            before do
              expect(client).to receive(:find_on).once.with(
                                  :stub_entities,
                                  filter: { period: Date.parse('January/2016') },
                                  sort: {}
                                ).and_return(
                                  [
                                    { '_id' => 124 },
                                    { '_id' => 125 }
                                  ]
                                )
            end

            it 'returns a set of entity objects already loaded' do
              expect(::StubEntity).not_to receive(:new).with(
                                                { '_id' => 124 }
                                              )

              expect(::StubEntity).to receive(:new).once.with(
                                            { '_id' => 125 }
                                          ).and_return entity

              expect(uow).to receive(:track_clean).once.with(entity).and_return entity

              expect(
                subject.find_all(filter: { period: Date.parse('January/2016') })
              ).to eql [@loaded_entity, entity]
            end
          end

          context 'when not provided with a query filter' do
            before do
              expect(client).to receive(:find_on).once.with(
                                  :stub_entities, filter: {}, sort: {}
                                ).and_return(
                                  [
                                    { '_id' => 124 },
                                    { '_id' => 125 }
                                  ]
                                )
            end

            it 'returns all documents as entity objects' do
              expect(::StubEntity).not_to receive(:new).with(
                                                { '_id' => 124 }
                                              )

              expect(::StubEntity).to receive(:new).once.with(
                                            { '_id' => 125 }
                                          ).and_return entity

              expect(uow).to receive(:track_clean).once.with(entity).and_return entity

              expect(subject.find_all).to eql [@loaded_entity, entity]
            end
          end

          context 'when provided with a sorted_by option' do
            before do
              expect(client).to receive(:find_on).with(
                                  :stub_entities, filter: {}, sort: { period: 1 }
                                ).and_return(
                                  [
                                    { '_id' => 124 },
                                    { '_id' => 125 }
                                  ]
                                )
            end

            it 'returns all documents sorted as entity objects' do
              expect(::StubEntity).not_to receive(:new).with(
                                                { '_id' => 124 }
                                              )

              expect(::StubEntity).to receive(:new).once.with(
                                            { '_id' => 125 }
                                          ).and_return entity

              expect(uow).to receive(:track_clean).once.with(entity).and_return entity

              expect(subject.find_all(sorted_by: { period: 1 })).to eql [@loaded_entity, entity]
            end
          end
        end
      end

      describe '#insert entity' do
        it 'saves an entry from entity instance on collection, based on its mapped fields' do
          allow(entity_to_save).to receive(:to_mongo_document).once.and_return(
                             _id: 1, amount: 200.0, period: Date.parse('1990/01/01')
                           )

          expect(client).to receive(:insert_on).once.with(
                              :stub_entities,
                              _id: 1, amount: 200.0, period: Date.parse('1990/01/01')
                            )

          subject.insert entity_to_save
        end

        it "raises InvalidEntityError if entity isn't an instance of entity_klass" do
          entity = OpenStruct.new
          expect(entity).not_to receive(:to_mongo_document)
          expect(client).not_to receive(:insert_on).with(any_args)

          expect {
            subject.insert entity
          }.to raise_error(
                 InvalidEntityError,
                 "Entity must be of class: StubEntity. "\
                 "This repository cannot operate on OpenStruct entities."
               )
        end

        it "raises InvalidEntityError if entity doesn't have id field set" do
          expect(entity_to_save).to receive(:id).and_return nil

          expect(entity_to_save).not_to receive(:to_mongo_document)
          expect(client).not_to receive(:insert_on).with(any_args)

          expect {
            subject.insert entity_to_save
          }.to raise_error(InvalidEntityError, 'Entity must have an \'id\' field set.')
        end

        it 'raises Repositories::InsertionError when insertion fails' do
          allow(entity_to_save).to receive(:to_mongo_document).once.and_return(
                                     _id: 1, amount: 200.0, period: Date.parse('1990/01/01')
                                   )

          expect(client).to receive(:insert_on).once.with(
                              :stub_entities,
                              _id: 1, amount: 200.0, period: Date.parse('1990/01/01')
                            ).and_raise(Databases::OperationError, 'Error')

          expect {
            subject.insert entity_to_save
          }.to raise_error(Repositories::InsertionError, "Error on insertion operation. Reason: 'Error'")
        end
      end

      describe '#update entity' do
        it 'calls document update on collection, using entity id as identifier' do
          expect(entity_to_save).to receive(
                                      :to_mongo_document
                                    ).once.with(include_id_field: false).and_return(
                                      amount: 200.0, period: Date.parse('1990/01/01')
                                    )

          expect(client).to receive(:update_on).once.with(
                              :stub_entities,
                              { _id: entity_to_save.id },
                              { '$set' => { amount: 200.0, period: Date.parse('1990/01/01') } }
                            )

          subject.update entity_to_save
        end

        it "raises InvalidEntityError if entity isn't an instance of entity_klass" do
          entity = OpenStruct.new
          expect(entity).not_to receive(:to_mongo_document).with(any_args)
          expect(client).not_to receive(:update_on).with(any_args)

          expect {
            subject.update entity
          }.to raise_error(
                 InvalidEntityError,
                 "Entity must be of class: StubEntity. "\
                 "This repository cannot operate on OpenStruct entities."
               )
        end

        it "raises InvalidEntityError if entity doesn't have id field set" do
          allow(entity_to_save).to receive(:id).and_return nil

          expect(entity_to_save).not_to receive(:to_mongo_document)
          expect(client).not_to receive(:update_on).with(any_args)

          expect {
            subject.update entity_to_save
          }.to raise_error(InvalidEntityError, 'Entity must have an \'id\' field set.')
        end

        it 'raises Repositories::UpdateError when update operation fails' do
          expect(entity_to_save).to receive(
                                      :to_mongo_document
                                    ).once.with(include_id_field: false).and_return(
                                      amount: 200.0, period: Date.parse('1990/01/01')
                                    )

          expect(client).to receive(:update_on).once.with(
                              :stub_entities,
                              { _id: entity_to_save.id },
                              { '$set' => { amount: 200.0, period: Date.parse('1990/01/01') } }
                            ).and_raise Databases::OperationError, 'Error'

          expect {
            subject.update entity_to_save
          }.to raise_error(Repositories::UpdateError, "Error on update operation. Reason: 'Error'")
        end
      end

      describe '#delete entity' do
        it 'calls document delete on collection, using entity id as identifier' do
          allow(entity_to_save).to receive(:id).and_return '123'

          expect(client).to receive(:delete_from).once.with(:stub_entities, _id: '123')

          subject.delete entity_to_save
        end

        it "raises InvalidEntityError if entity isn't an instance of entity_klass" do
          expect(client).not_to receive(:delete_from).with(any_args)

          expect {
            subject.delete OpenStruct.new
          }.to raise_error(
                 InvalidEntityError,
                 "Entity must be of class: StubEntity. "\
                 "This repository cannot operate on OpenStruct entities."
               )
        end

        it "raises InvalidEntityError if entity doesn't have id field set" do
          allow(entity_to_save).to receive(:id).and_return nil
          expect(client).not_to receive(:delete_from).with(any_args)

          expect {
            subject.delete entity_to_save
          }.to raise_error(InvalidEntityError, 'Entity must have an \'id\' field set.')
        end

        it 'raises Repositories::DeleteError when delete operation fails' do
          expect(client).to receive(:delete_from).once.with(
                              :stub_entities, _id: entity_to_save.id
                            ).and_raise(Databases::OperationError, 'Error')

          expect {
            subject.delete entity_to_save
          }.to raise_error(Repositories::DeleteError, "Error on delete operation. Reason: 'Error'")
        end
      end

      describe '#aggregate &block' do
        it 'calls aggregation pipeline on collection, allowing stage append on block' do
          expect do |b|
            expect(client).to receive(:aggregate_on).once.with(
                                :stub_entities, &b
                              ).and_return([{ '_id' => 'Sum', 'count' => 12 }])

            expect(subject.aggregate(&b)).to eql [{ '_id' => 'Sum', 'count' => 12 }]
          end.to yield_control
        end
      end
    end
  end
end
