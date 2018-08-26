describe 'DocumentManager integration tests', db_integration: true do
  include_context 'StubRepository'
  include_context 'StubEntity'

  let(:dm) { Persisty::DocumentManager.new }
  let(:uow) { Persisty::Persistence::UnitOfWork.current }

  context 'persisting on UnitOfWork and inserting on database' do
    it "persists entity setting its ID field" do
      dm.persist entity

      expect(uow.managed?(entity)).to be true
      expect(entity.id).not_to be_nil
    end

    it "doesn't change entity id when persisting entity with id" do
      id = BSON::ObjectId.new

      entity.id = id

      dm.persist entity
      expect(uow.managed?(entity)).to be true
      expect(entity.id).to eql id
    end

    it "can't persist an entity that will be removed" do
      id = BSON::ObjectId.new
      entity.id = id
      dm.remove entity

      dm.persist entity

      expect(uow.managed?(entity)).to be false
    end

    it "can't persist an entity about to be updated" do
      dm.persist entity
      dm.commit

      loaded_entity = dm.find(entity.class, entity.id)

      loaded_entity.age = 48
      loaded_entity.first_name = 'Joe'

      dm.persist loaded_entity
      dm.persist entity

      expect(uow.new_entities).not_to include loaded_entity
      expect(uow.new_entities).not_to include entity
    end

    it 'raises ArgumentError when trying to change ID from a persisted entity' do
      dm.persist entity

      expect {
        entity.id = BSON::ObjectId.new
      }.to raise_error(ArgumentError, 'Cannot change ID from an entity that is still on current UnitOfWork')
    end

    it 'correctly inserts entity into database' do
      dm.persist entity
      expect(dm.commit).to be true
    end

    it 'changes ID from detached entity, without marking on UnitOfWork' do
      dm.persist entity
      dm.commit

      dm.detach entity
      new_id = BSON::ObjectId.new

      entity._id = new_id

      expect(entity.id).to eql new_id
    end

    context 'handling single child nodes' do
      include_context 'parent node and childs environment'

      it 'persists parent and its childs setting all IDs' do
        expect {
          expect {
            parent.first_child = child_one
            parent.child_two = child_two

            dm.persist(parent)
            expect(uow.new_entities).to include parent, child_one, child_two

            dm.commit

            expect(parent.id).not_to be_nil
            expect(child_one.parent).to eql parent
            expect(child_one.parent_id).to eql parent.id

            expect(child_two.dad).to eql parent
            expect(child_two.dad_id).to eql parent.id

            expect(uow.managed?(parent)).to be true
            expect(uow.managed?(child_one)).to be true
            expect(uow.managed?(child_two)).to be true
          }.to change(child_one, :id)
        }.to change(child_two, :id)
      end

      it 'persists only parent when child is already persisted' do
        dm.persist child_one
        expect(child_one.id).not_to be_nil
        expect(Persisty::Persistence::UnitOfWork.current.new_entities).to include child_one

        dm.commit

        parent.first_child = child_one

        dm.persist(parent)
        expect(parent.id).not_to be_nil
        expect(Persisty::Persistence::UnitOfWork.current.new_entities).to include parent
        expect(Persisty::Persistence::UnitOfWork.current.new_entities).not_to include child_one

        dm.commit

        expect(child_one.parent).to eql parent
        expect(child_one.parent_id).to eql parent.id

        expect(Persisty::Persistence::UnitOfWork.current.managed?(parent)).to be true
        expect(Persisty::Persistence::UnitOfWork.current.managed?(child_one)).to be true
      end

      it 'persists only child when parent is already persisted' do
        dm.persist(parent)
        expect(parent.id).not_to be_nil
        expect(Persisty::Persistence::UnitOfWork.current.new_entities).to include parent

        dm.commit

        parent.first_child = child_one

        dm.persist parent
        expect(child_one.id).not_to be_nil
        expect(Persisty::Persistence::UnitOfWork.current.new_entities).not_to include parent
        expect(Persisty::Persistence::UnitOfWork.current.new_entities).to include child_one

        dm.commit

        expect(child_one.parent).to eql parent
        expect(child_one.parent_id).to eql parent.id

        expect(Persisty::Persistence::UnitOfWork.current.managed?(parent)).to be true
        expect(Persisty::Persistence::UnitOfWork.current.managed?(child_one)).to be true
      end

      it 'persists parent and its childs setting only foreign keys' do
        child_one.id = BSON::ObjectId.new
        child_two.id = BSON::ObjectId.new

        expect {
          expect {
            parent.first_child = child_one
            parent.child_two = child_two

            dm.persist(parent)
            expect(uow.new_entities).to include parent, child_one, child_two

            dm.commit

            expect(parent.id).not_to be_nil
            expect(child_one.parent).to eql parent
            expect(child_one.parent_id).to eql parent.id

            expect(child_two.dad).to eql parent
            expect(child_two.dad_id).to eql parent.id

            expect(uow.managed?(parent)).to be true
            expect(uow.managed?(child_one)).to be true
            expect(uow.managed?(child_two)).to be true
          }.not_to change(child_one, :id)
        }.not_to change(child_two, :id)
      end

      it 'persists parent correctly when any child is missing' do
        expect {
          parent.first_child = child_one

          dm.persist(parent)
          expect(uow.new_entities).to include parent, child_one

          dm.commit

          expect(parent.id).not_to be_nil
          expect(child_one.parent).to eql parent
          expect(child_one.parent_id).to eql parent.id

          expect(parent.child_two).to be_nil

          expect(uow.managed?(parent)).to be true
          expect(uow.managed?(child_one)).to be true
        }.to change(child_one, :id)
      end

      it 'persists only child without going upwards to parent' do
        expect {
          parent.first_child = child_one

          dm.persist(child_one)

          dm.commit

          expect(parent.id).to be_nil
          expect(child_one.parent).to eql parent
          expect(child_one.parent_id).to be_nil

          expect(uow.managed?(parent)).to be false
          expect(uow.managed?(child_one)).to be true
        }.to change(child_one, :id)
      end
    end
  end

  context 'removing entities' do
    it 'sets entity as removed on UnitOfWork' do
      entity.id = BSON::ObjectId.new

      dm.remove entity

      expect(uow.removed_entities).to include entity
    end

    it 'removes entity from managed state when removing it' do
      dm.persist entity

      expect(uow.managed?(entity)).to be true

      dm.remove entity

      expect(uow.managed?(entity)).to be false
    end

    it 'raises ArgumentError when trying to change ID from a removed entity' do
      dm.persist entity

      expect {
        entity.id = BSON::ObjectId.new
      }.to raise_error(ArgumentError, 'Cannot change ID from an entity that is still on current UnitOfWork')
    end

    it 'removes an entity loaded from database' do
      dm.persist entity
      dm.commit

      loaded_entity = dm.find(entity.class, entity.id)

      dm.remove loaded_entity

      expect(uow.managed?(entity)).to be false
      expect(uow.managed?(loaded_entity)).to be false
    end

    it 'changes ID from detached entity, without marking on UnitOfWork' do
      dm.persist entity
      dm.commit

      dm.remove entity
      dm.detach entity
      new_id = BSON::ObjectId.new

      entity._id = new_id

      expect(entity.id).to eql new_id
    end
  end

  context 'updating entities' do
    before do
      dm.persist entity
      dm.commit
    end

    it 'correctly marks entity as to be updated on UnitOfWork' do
      entity.first_name = 'John'

      expect(uow.managed?(entity)).to be true
    end

    it 'correctly updates name on database' do
      entity.first_name = 'John'

      expect(entity.first_name).to eql 'John'

      dm.commit

      expect(entity.first_name).to eql 'John'

      dm.detach(entity)

      loaded_entity = dm.find(entity.class, entity.id)

      expect(loaded_entity.first_name).to eql 'John'
    end

    it 'raises ArgumentError when trying to change ID from a changed entity' do
      entity.first_name = 'John'

      expect {
        entity._id = BSON::ObjectId.new
      }.to raise_error(ArgumentError, 'Cannot change ID from an entity that is still on current UnitOfWork')
    end

    it 'changes ID from detached entity, without marking on UnitOfWork' do
      entity.first_name = 'John'

      dm.detach entity
      new_id = BSON::ObjectId.new

      entity._id = new_id

      expect(entity.id).to eql new_id
    end
  end
end
