module Persisty
  describe DocumentManager do
    let(:client) { double(:client, id_generator: id_gen) }
    let(:id_gen) { double(:id_generator) }
    let(:unit_of_work) { double(:unit_of_work) }
    let(:repository) { double(:repository) }
    let(:entity) { double(:entity, id: BSON::ObjectId.new) }

    before do
      allow(
        Databases::MongoDB::Client
      ).to receive(:current_or_new_connection).once.and_return client

      allow(Persistence::UnitOfWork).to receive(:current).and_return unit_of_work
    end

    describe 'initialization' do
      context "when unit of work isn't already set" do
        it 'initializes with a new Persistence::UnitOfWork object' do
          allow(Persistence::UnitOfWork).to receive(:current).once.and_raise(
                                              Persistence::UnitOfWorkNotStartedError
                                            )

          expect(
            Persistence::UnitOfWork
          ).to receive(:new_current).once.and_return unit_of_work

          described_class.new
        end
      end
    end

    describe '#find entity_type, entity_id' do
      before do
        expect(
          subject
        ).to receive(:repository_for).once.with(Class).and_return repository
      end

      context 'when entity is not found' do
        it 'raises Repositories::EntityNotFoundError' do
          expect(repository).to receive(:find).once.with(entity.id).and_raise(
                                  Repositories::EntityNotFoundError.new(
                                    id: entity.id, entity_name: Class
                                  )
                                )

          expect {
            subject.find(Class, entity.id)
          }.to raise_error(an_instance_of(Repositories::EntityNotFoundError))
        end
      end

      context 'when entity is found' do
        it 'returns entity' do
          expect(repository).to receive(:find).once.with(entity.id).and_return entity

          expect(subject.find(Class, entity.id)).to eql entity
        end
      end
    end

    describe '#find_all entity_type, filter: {}, **options' do
      before do
        expect(
          subject
        ).to receive(:repository_for).once.with(Class).and_return repository
      end

      it 'returns collection of entities from query without filter or sort' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(filter: {}).and_return [entity]

        expect(subject.find_all(Class)).to eql [entity]
      end

      it 'returns collection of entities from query with filter, without sort' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(
                                filter: { foo: 'bar' }
                              ).and_return [entity]

        expect(
          subject.find_all(Class, filter: { foo: 'bar' })
        ).to eql [entity]
      end

      it 'returns collection of entities from query without filter, with sort' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(
                                filter: {}, sort: { foo: -1 }
                              ).and_return [entity]

        expect(
          subject.find_all(Class, sort: { foo: -1 })
        ).to eql [entity]
      end

      it 'returns collection of entities from query with limit only' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(
                                filter: {}, limit: 1
                              ).and_return [entity]

        expect(
          subject.find_all(Class, limit: 1)
        ).to eql [entity]
      end

      it 'returns collection of entities from query with filter and sort' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(
                                filter: { foo: 'bar' }, sort: { foo: -1 }
                              ).and_return [entity]

        expect(
          subject.find_all(Class, filter: { foo: 'bar' }, sort: { foo: -1 })
        ).to eql [entity]
      end

      it 'returns collection of entities from query with filter and limit' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(
                                filter: { foo: 'bar' }, limit: 1
                              ).and_return [entity]

        expect(
          subject.find_all(Class, filter: { foo: 'bar' }, limit: 1)
        ).to eql [entity]
      end

      it 'returns collection of entities from query with sort and limit' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(
                                filter: {}, sort: { foo: -1 }, limit: 1
                              ).and_return [entity]

        expect(
          subject.find_all(Class, sort: { foo: -1 }, limit: 1)
        ).to eql [entity]
      end

      it 'returns collection of entities from query with filter, sort and limit' do
        expect(repository).to receive(
                                :find_all
                              ).once.with(
                                filter: { foo: 'bar' }, sort: { foo: -1 }, limit: 1
                              ).and_return [entity]

        expect(
          subject.find_all(Class, filter: { foo: 'bar' }, sort: { foo: -1 }, limit: 1)
        ).to eql [entity]
      end
    end

    describe '#repository_for entity_type' do
      it 'returns repository found for entity_type from registry' do
        expect(
          Repositories::Registry
        ).to receive(:[]).once.with(Class).and_return repository

        expect(subject.repository_for(Class)).to eql repository
      end
    end

    describe '#persist entity' do
      context "when entity hasn't an ID" do
        before do
          allow(entity).to receive(:id).and_return nil
          allow(entity).to receive(:child_nodes_list).and_return []
          allow(entity).to receive(:child_nodes_collections_list).and_return []
        end

        it 'sets entity ID and registers on Persistence::UnitOfWork as new' do
          expect(id_gen).to receive(:generate).once.and_return 123
          expect(entity).to receive(:id=).once.with(123)
          expect(unit_of_work).to receive(:register_new).once.with(entity)
          subject.persist entity
        end
      end

      context 'when entity already has an ID' do
        it "doesn't replace entity's ID and just calls Persistence::UnitOfWork registration" do
          allow(entity).to receive(:child_nodes_list).and_return []
          allow(entity).to receive(:child_nodes_collections_list).and_return []
          expect(id_gen).not_to receive(:generate)
          expect(entity).not_to receive(:id=).with(any_args)
          expect(unit_of_work).to receive(:register_new).once.with(entity)
          subject.persist entity
        end
      end

      context 'handling entity child nodes collections' do
        let(:child_one) { double(:child_one) }
        let(:child_two) { double(:child_two) }

        before do
          allow(entity).to receive(:id).and_return nil
          allow(entity).to receive(:class).and_return Object
          expect(entity).to receive(:child_nodes_list).and_return []
          expect(entity).to receive(:child_nodes_collections_list).and_return [:child_ones, :child_twos]
          expect(id_gen).to receive(:generate).once.and_return 123
          expect(entity).to receive(:id=).once.with(123)
        end

        it 'sets entity ID, same ID as foreign key on each child, registers entity and childs as new' do
          expect(entity).to receive(:child_ones).once.and_return [child_one]

          allow(child_one).to receive(:id).and_return nil
          expect(id_gen).to receive(:generate).once.and_return 124
          expect(child_one).to receive(:id=).once.with(124)
          expect(child_one).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(entity).to receive(:child_twos).once.and_return [child_two]
          allow(child_two).to receive(:id).and_return nil
          expect(id_gen).to receive(:generate).once.and_return 125
          expect(child_two).to receive(:id=).once.with(125)
          expect(child_two).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(unit_of_work).to receive(:register_new).once.with(entity)
          expect(unit_of_work).to receive(:register_new).once.with(child_one)
          expect(unit_of_work).to receive(:register_new).once.with(child_two)

          subject.persist entity
        end

        it 'handles only foreign keys on childs when their IDs are already set' do
          expect(entity).to receive(:child_ones).once.and_return [child_one]
          allow(child_one).to receive(:id).and_return 124
          expect(child_one).not_to receive(:id=).with(any_args)
          expect(child_one).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(entity).to receive(:child_twos).once.and_return [child_two]
          allow(child_two).to receive(:id).and_return 125
          expect(child_two).not_to receive(:id=).with(any_args)
          expect(child_two).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(unit_of_work).to receive(:register_new).once.with(entity)
          expect(unit_of_work).to receive(:register_new).once.with(child_one)
          expect(unit_of_work).to receive(:register_new).once.with(child_two)

          subject.persist entity
        end
      end

      context 'handling entity single child nodes' do
        let(:child_one) { double(:child_one) }
        let(:child_two) { double(:child_two) }

        before do
          allow(entity).to receive(:id).and_return nil
          allow(entity).to receive(:class).and_return Object
          expect(entity).to receive(:child_nodes_list).and_return [:child_one, :child_two]
          allow(entity).to receive(:child_nodes_collections_list).and_return []
          expect(id_gen).to receive(:generate).once.and_return 123
          expect(entity).to receive(:id=).once.with(123)
        end

        it 'sets entity ID, same ID as foreign key on childs, registers entity and childs as new' do
          expect(entity).to receive(:child_one).once.and_return child_one
          allow(child_one).to receive(:id).and_return nil
          expect(id_gen).to receive(:generate).once.and_return 124
          expect(child_one).to receive(:id=).once.with(124)
          expect(child_one).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(entity).to receive(:child_two).once.and_return child_two
          allow(child_two).to receive(:id).and_return nil
          expect(id_gen).to receive(:generate).once.and_return 125
          expect(child_two).to receive(:id=).once.with(125)
          expect(child_two).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(unit_of_work).to receive(:register_new).once.with(entity)
          expect(unit_of_work).to receive(:register_new).once.with(child_one)
          expect(unit_of_work).to receive(:register_new).once.with(child_two)

          subject.persist entity
        end

        it 'handles only foreign keys on childs when their IDs are already set' do
          expect(entity).to receive(:child_one).once.and_return child_one
          allow(child_one).to receive(:id).and_return 124
          expect(child_one).not_to receive(:id=).with(any_args)
          expect(child_one).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(entity).to receive(:child_two).once.and_return child_two
          allow(child_two).to receive(:id).and_return 125
          expect(child_two).not_to receive(:id=).with(any_args)
          expect(child_two).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(unit_of_work).to receive(:register_new).once.with(entity)
          expect(unit_of_work).to receive(:register_new).once.with(child_one)
          expect(unit_of_work).to receive(:register_new).once.with(child_two)

          subject.persist entity
        end

        it 'handles missing childs without trying to persist nil values' do
          expect(entity).to receive(:child_one).once.and_return child_one
          allow(child_one).to receive(:id).and_return 124
          expect(child_one).not_to receive(:id=).with(any_args)
          expect(child_one).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          expect(entity).to receive(:child_two).once.and_return nil

          expect(unit_of_work).to receive(:register_new).once.with(entity)
          expect(unit_of_work).to receive(:register_new).once.with(child_one)

          subject.persist entity
        end
      end
    end

    describe '#remove entity' do
      it 'calls removed registration of entity on Persistence::UnitOfWork' do
        expect(entity).to receive(:child_nodes_list).and_return []
        expect(entity).to receive(:child_nodes_collections_list).and_return []
        expect(unit_of_work).to receive(:register_removed).once.with(entity)
        subject.remove entity
      end

      context 'handle collections of child nodes on entity' do
        let(:child_one) { double(:child_one) }
        let(:child_two) { double(:child_two) }

        before do
          expect(entity).to receive(:child_nodes_list).and_return []
          expect(entity).to receive(:child_nodes_collections_list).and_return [:child_ones, :child_twos]
        end

        it 'registers parent and all childs from each collection to be removed' do
          expect(entity).to receive(:child_ones).once.and_return [child_one]
          expect(entity).to receive(:child_twos).once.and_return [child_two]

          expect(unit_of_work).to receive(:register_removed).once.with(entity)
          expect(unit_of_work).to receive(:register_removed).once.with(child_one)
          expect(unit_of_work).to receive(:register_removed).once.with(child_two)

          subject.remove entity
        end
      end

      context 'handling single child nodes on entity' do
        let(:child_one) { double(:child_one) }
        let(:child_two) { double(:child_two) }

        before do
          expect(entity).to receive(:child_nodes_list).and_return [:child_one, :child_two]
          expect(entity).to receive(:child_nodes_collections_list).and_return []
        end

        it 'registers all childs and parent to be removed' do
          expect(entity).to receive(:child_one).once.and_return child_one
          expect(entity).to receive(:child_two).once.and_return child_two

          expect(unit_of_work).to receive(:register_removed).once.with(entity)
          expect(unit_of_work).to receive(:register_removed).once.with(child_one)
          expect(unit_of_work).to receive(:register_removed).once.with(child_two)

          subject.remove entity
        end

        it 'registers child to be removed skipping any nil childs' do
          expect(entity).to receive(:child_one).once.and_return child_one
          expect(entity).to receive(:child_two).once.and_return nil

          expect(unit_of_work).to receive(:register_removed).once.with(entity)
          expect(unit_of_work).to receive(:register_removed).once.with(child_one)

          subject.remove entity
        end
      end
    end

    describe '#commit' do
      context 'when unit of work processes correctly' do
        it 'commits unit of work and starts new one on thread' do
          expect(unit_of_work).to receive(:commit).once.and_return true
          expect(Persistence::UnitOfWork).to receive(:new_current).once

          expect(subject.commit).to be true
        end
      end

      context 'when a operation fails inside unit of work commit' do
        it 'starts new unit of work and raises error' do
          expect(unit_of_work).to receive(:commit).once.and_raise(
                                    Repositories::DeleteError, 'Error'
                                  )

          expect(Persistence::UnitOfWork).to receive(:new_current).once

          expect {
            subject.commit
          }.to raise_error(Repositories::DeleteError)
        end
      end
    end

    describe '#detach entity' do
      it 'calls detach process for entity on Persistence::UnitOfWork' do
        expect(unit_of_work).to receive(:detach).once.with(entity)
        subject.detach entity
      end
    end

    describe '#clear' do
      it 'calls clear process on Persistence::UnitOfWork' do
        expect(unit_of_work).to receive(:clear).once
        subject.clear
      end
    end
  end
end
