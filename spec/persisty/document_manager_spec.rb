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
          allow(entity).to receive(:cascading_child_node_objects).and_return []
          allow(entity).to receive(:cascading_child_nodes_objects).and_return []
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
          allow(entity).to receive(:cascading_child_node_objects).and_return []
          allow(entity).to receive(:cascading_child_nodes_objects).and_return []
          expect(id_gen).not_to receive(:generate)
          expect(entity).not_to receive(:id=).with(any_args)
          expect(unit_of_work).to receive(:register_new).once.with(entity)
          subject.persist entity
        end
      end

      context 'handling entity child nodes' do
        let(:child_ones) { [child_one] }
        let(:child_one_level_2_last) { double(cascading_child_node_objects: [], cascading_child_nodes_objects: []) }
        let(:child_one_level_2_collection) { [child_one_level_2_last] }

        let(:child_one_children) do
          [
            double(:child_one_level_1, cascading_child_node_objects: [], cascading_child_nodes_objects: []),
            double(:child_one_level_1, class: Symbol, cascading_child_node_objects: [child_one_level_2_first], cascading_child_nodes_objects: []),
            double(:child_one_level_1, class: Symbol, cascading_child_node_objects: [], cascading_child_nodes_objects: [child_one_level_2_collection])
          ]
        end

        let(:child_one_level_2_first) { double(:child_one_level_2, cascading_child_node_objects: [], cascading_child_nodes_objects: []) }
        let(:child_one) { double(:child_one, class: Float, cascading_child_node_objects: [child_one_children[0]], cascading_child_nodes_objects: [child_one_children[1..2]]) }
        let(:child_two) { double(:child_two, cascading_child_node_objects: [], cascading_child_nodes_objects: []) }

        before do
          allow(entity).to receive(:id).and_return nil
          allow(entity).to receive(:class).and_return Object
          expect(entity).to receive(:cascading_child_node_objects).and_return [child_two]
          expect(entity).to receive(:cascading_child_nodes_objects).and_return [child_ones]
          allow(id_gen).to receive(:generate).and_return 123, 130, 124, 125, 126, 128, 127, 129
          expect(entity).to receive(:id=).once.with(123)
        end

        it 'sets entity ID, same ID as foreign key on each child, registers entity and childs as new' do
          allow(child_one).to receive(:id).and_return nil
          expect(child_one).to receive(:id=).once.with(124)
          expect(child_one).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          allow(child_one_children[0]).to receive(:id).and_return nil
          expect(child_one_children[0]).to receive(:id=).once.with(125)
          expect(child_one_children[0]).to receive(:set_foreign_key_for).once.with(Float, child_one.id)

          allow(child_one_children[1]).to receive(:id).and_return nil
          expect(child_one_children[1]).to receive(:id=).once.with(126)
          expect(child_one_children[1]).to receive(:set_foreign_key_for).once.with(Float, child_one.id)

          allow(child_one_level_2_first).to receive(:id).and_return nil
          expect(child_one_level_2_first).to receive(:id=).once.with(128)
          expect(child_one_level_2_first).to receive(:set_foreign_key_for).once.with(Symbol, child_one_children[1].id)

          allow(child_one_children[2]).to receive(:id).and_return nil
          expect(child_one_children[2]).to receive(:id=).once.with(127)
          expect(child_one_children[2]).to receive(:set_foreign_key_for).once.with(Float, child_one.id)

          allow(child_one_level_2_last).to receive(:id).and_return nil
          expect(child_one_level_2_last).to receive(:id=).once.with(129)
          expect(child_one_level_2_last).to receive(:set_foreign_key_for).once.with(Symbol, child_one_children[2].id)

          allow(child_two).to receive(:id).and_return nil
          expect(child_two).to receive(:id=).once.with(130)
          expect(child_two).to receive(:set_foreign_key_for).once.with(Object, entity.id)

          [
            entity, child_one, child_two, *child_one_children,
            child_one_level_2_first, child_one_level_2_last
          ].each do |obj|
            expect(unit_of_work).to receive(:register_new).once.with(obj)
          end

          subject.persist entity
        end
      end
    end

    describe '#remove entity' do
      it 'calls removed registration of entity on Persistence::UnitOfWork' do
        allow(entity).to receive(:cascading_child_node_objects).and_return []
        allow(entity).to receive(:cascading_child_nodes_objects).and_return []
        expect(unit_of_work).to receive(:register_removed).once.with(entity)
        subject.remove entity
      end

      context 'handle cascading child nodes on entity' do
        let(:child_one) { double(:child_one) }
        let(:child_two) { double(:child_two) }

        let(:child_ones) { [child_one] }
        let(:child_one_level_2_last) { double(cascading_child_node_objects: [], cascading_child_nodes_objects: []) }
        let(:child_one_level_2_collection) { [child_one_level_2_last] }

        let(:child_one_children) do
          [
            double(:child_one_level_1, cascading_child_node_objects: [], cascading_child_nodes_objects: []),
            double(:child_one_level_1, cascading_child_node_objects: [child_one_level_2_first], cascading_child_nodes_objects: []),
            double(:child_one_level_1, cascading_child_node_objects: [], cascading_child_nodes_objects: [child_one_level_2_collection])
          ]
        end

        let(:child_one_level_2_first) { double(:child_one_level_2, cascading_child_node_objects: [], cascading_child_nodes_objects: []) }
        let(:child_one) { double(:child_one, cascading_child_node_objects: [child_one_children[0]], cascading_child_nodes_objects: [child_one_children[1..2]]) }
        let(:child_two) { double(:child_two, cascading_child_node_objects: [], cascading_child_nodes_objects: []) }

        before do
          expect(entity).to receive(:cascading_child_node_objects).and_return [child_two]
          expect(entity).to receive(:cascading_child_nodes_objects).and_return [child_ones]
        end

        it 'registers parent and all childs from each collection to be removed' do
          [
            entity, child_one, child_two, *child_one_children,
            child_one_level_2_first, child_one_level_2_last
          ].each do |obj|
            expect(unit_of_work).to receive(:register_removed).once.with(obj)
          end

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
