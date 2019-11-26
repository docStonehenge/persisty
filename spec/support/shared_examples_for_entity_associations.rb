shared_examples_for 'entity associations methods' do
  describe '.child_nodes name, class_name:, cascade:, foreign_key:' do
    let(:collection_builder) { double(:collection_builder) }

    before do
      @subject = described_class.new(id: BSON::ObjectId.new)
    end

    context 'when foreign_key is nil' do
      context 'when class_name is nil' do
        it 'adds name to child_nodes_collections map, list and sets accessors' do
          StubEntityForCollection.parent_node :test_class

          described_class.child_nodes :stub_entity_for_collections, cascade: true

          expect(@subject).to respond_to :stub_entity_for_collections
          expect(@subject).to respond_to(:stub_entity_for_collections=)

          expect(
            described_class.nodes_reference.values
          ).to include(a_hash_including(child_nodes: [{ node: :stub_entity_for_collections, class: ::StubEntityForCollection, cascade: true, foreign_key: nil }]))

          expect(
            StubEntityForCollection.nodes_reference.values
          ).to include(a_hash_including(child_nodes: [{ node: :stub_entity_for_collections, class: ::StubEntityForCollection, cascade: true, foreign_key: nil }]))
        end

        it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
          expect {
            described_class.child_nodes :stub_entity_for_collections
          }.to raise_error(
                 Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                 "Class must have a parent correctly set up. "\
                 "Use parent definition method on child class to set correct parent_node relation."
               )
        end

        it "raises NoParentNodeError when child node class doesn't have parent expected" do
          StubEntityForCollection.parent_node :foo, class_name: ::TestClass

          expect {
            described_class.child_nodes :stub_entity_for_collections
          }.to raise_error(
                 Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                 "Class must have a parent correctly set up. "\
                 "Use parent definition method on child class to set correct parent_node relation."
               )
        end

        it 'sets an instance of DocumentCollection on reader named after child node class' do
          StubEntityForCollection.parent_node :test_class

          described_class.child_nodes :stub_entity_for_collections

          collection = @subject.stub_entity_for_collections
          expect(collection).to be_an_instance_of(Persisty::Associations::StubEntityForCollectionDocumentCollection)
          expect(@subject.stub_entity_for_collections).to equal(collection)
        end

        it 'assigns a DocumentCollection on writer, using previous collection' do
          entities = [entity_for_collection]

          StubEntityForCollection.parent_node :test_class

          described_class.child_nodes :stub_entity_for_collections

          previous_collection = @subject.stub_entity_for_collections

          expect(Persisty::Persistence::DocumentDefinitions::DocumentCollectionBuilder).to receive(:new).once.with(
                                                 @subject,
                                                 @subject.stub_entity_for_collections,
                                                 StubEntityForCollection
                                               ).and_return collection_builder

          expect(
            collection_builder
          ).to receive(:build_with).once.with(entities, nil).and_return an_instance_of(Persisty::Associations::StubEntityForCollectionDocumentCollection)

          @subject.stub_entity_for_collections = entities

          expect(@subject.stub_entity_for_collections).not_to equal previous_collection
        end
      end

      context "when class_name isn't nil" do
        it 'adds name to child_nodes_collections map, list and sets accessors' do
          StubEntityForCollection.parent_node :test_class

          described_class.child_nodes :foos, class_name: StubEntityForCollection

          expect(@subject).to respond_to :foos
          expect(@subject).to respond_to(:foos=)

          expect(
            described_class.nodes_reference.values
          ).to include(a_hash_including(child_nodes: [{ node: :foos, class: ::StubEntityForCollection, cascade: false, foreign_key: nil }]))

          expect(
            StubEntityForCollection.nodes_reference.values
          ).to include(a_hash_including(child_nodes: [{ node: :foos, class: ::StubEntityForCollection, cascade: false, foreign_key: nil }]))
        end

        it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
          expect {
            described_class.child_nodes :foos, class_name: 'StubEntityForCollection'
          }.to raise_error(
                 Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                 "Class must have a parent correctly set up. "\
                 "Use parent definition method on child class to set correct parent_node relation."
               )
        end

        it "raises NoParentNodeError when child node class doesn't have parent expected" do
          StubEntityForCollection.parent_node :foo, class_name: ::TestClass

          expect {
            described_class.child_nodes :foos, class_name: 'StubEntityForCollection'
          }.to raise_error(
                 Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                 "Class must have a parent correctly set up. "\
                 "Use parent definition method on child class to set correct parent_node relation."
               )
        end

        it 'sets an instance of DocumentCollection on reader named after child node class' do
          StubEntityForCollection.parent_node :test_class

          described_class.child_nodes :foos, class_name: 'StubEntityForCollection'

          collection = @subject.foos
          expect(collection).to be_an_instance_of(Persisty::Associations::StubEntityForCollectionDocumentCollection)
          expect(@subject.foos).to equal(collection)
        end

        it 'assigns a DocumentCollection on writer, using previous collection' do
          entities = [entity_for_collection]

          StubEntityForCollection.parent_node :test_class

          described_class.child_nodes :foos, class_name: 'StubEntityForCollection'

          previous_collection = @subject.foos

          expect(Persisty::Persistence::DocumentDefinitions::DocumentCollectionBuilder).to receive(:new).once.with(
                                                 @subject,
                                                 @subject.foos,
                                                 StubEntityForCollection
                                               ).and_return collection_builder

          expect(
            collection_builder
          ).to receive(:build_with).once.with(entities, nil).and_return an_instance_of(Persisty::Associations::StubEntityForCollectionDocumentCollection)

          @subject.foos = entities

          expect(@subject.foos).not_to equal previous_collection
        end
      end
    end

    context "when foreign_key isn't nil" do
      it 'adds name to child_nodes_collections map, list and sets accessors' do
        StubEntityForCollection.parent_node :foo, class_name: ::TestClass

        described_class.child_nodes :stub_entity_for_collections, cascade: true, foreign_key: :foo_id

        expect(@subject).to respond_to :stub_entity_for_collections
        expect(@subject).to respond_to(:stub_entity_for_collections=)

        expect(
          described_class.nodes_reference.values
        ).to include(a_hash_including(child_nodes: [{ node: :stub_entity_for_collections, class: ::StubEntityForCollection, cascade: true, foreign_key: :foo_id }]))

        expect(
          StubEntityForCollection.nodes_reference.values
        ).to include(a_hash_including(child_nodes: [{ node: :stub_entity_for_collections, class: ::StubEntityForCollection, cascade: true, foreign_key: :foo_id }]))
      end

      it 'adds name to child_nodes_collections map, even with redundant foreign_key' do
        StubEntityForCollection.parent_node :test_class

        described_class.child_nodes :stub_entity_for_collections, cascade: true, foreign_key: :test_class_id

        expect(@subject).to respond_to :stub_entity_for_collections
        expect(@subject).to respond_to(:stub_entity_for_collections=)

        expect(
          described_class.nodes_reference.values
        ).to include(a_hash_including(child_nodes: [{ node: :stub_entity_for_collections, class: ::StubEntityForCollection, cascade: true, foreign_key: :test_class_id }]))

        expect(
          StubEntityForCollection.nodes_reference.values
        ).to include(a_hash_including(child_nodes: [{ node: :stub_entity_for_collections, class: ::StubEntityForCollection, cascade: true, foreign_key: :test_class_id }]))
      end

      it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
        expect {
          described_class.child_nodes :foos, class_name: 'StubEntityForCollection', foreign_key: :foo_id
        }.to raise_error(
               Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
               "Class must have a parent correctly set up. "\
               "Use parent definition method on child class to set correct parent_node relation."
             )
      end

      it "raises NoParentNodeError when child node class doesn't have parent expected" do
        StubEntityForCollection.parent_node :test_class

        expect {
          described_class.child_nodes :foos, class_name: 'StubEntityForCollection', foreign_key: :bar_id
        }.to raise_error(
               Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
               "Class must have a parent correctly set up. "\
               "Use parent definition method on child class to set correct parent_node relation."
             )
      end
    end
  end

  describe '.child_node name, class_name:, cascade:, foreign_key:' do
    before do
      @subject = described_class.new(id: BSON::ObjectId.new)
    end

    context 'when foreign_key is nil' do
      context 'when class_name is nil' do
        it 'sets child node field to lazy load object' do
          StubEntity.parent_node :test_class

          described_class.child_node :stub_entity, cascade: true

          expect(@subject).to respond_to :stub_entity
          expect(@subject).to respond_to(:stub_entity=)

          expect(
            described_class.nodes_reference.values
          ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil }]))

          expect(
            StubEntity.nodes_reference.values
          ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: nil }]))
        end

        it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
          expect {
            described_class.child_node :stub_entity
          }.to raise_error(
                 Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                 "Class must have a parent correctly set up. "\
                 "Use parent definition method on child class to set correct parent_node relation."
               )
        end

        it "raises NoParentNodeError when child node class doesn't have parent expected" do
          StubEntity.parent_node :foo, class_name: ::TestClass

          expect {
            described_class.child_node :stub_entity
          }.to raise_error(
                 Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                 "Class must have a parent correctly set up. "\
                 "Use parent definition method on child class to set correct parent_node relation."
               )
        end

        it 'performs lazy load on child node reader finding by parent id' do
          StubEntity.parent_node :test_class

          described_class.child_node :stub_entity

          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

          expect(
            Persisty::Repositories::Registry
          ).to receive(:[]).once.with(StubEntity).and_return repository

          expect(
            repository
          ).to receive(:find_all).once.with(filter: { test_class_id: @subject.id }).and_return [entity]

          expect(@subject.stub_entity).to eql entity
          expect(@subject.instance_variable_get(:@stub_entity)).to eql entity
        end

        it 'returns nil on reader when no child has been found' do
          StubEntity.parent_node :test_class

          described_class.child_node :stub_entity

          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

          expect(
            Persisty::Repositories::Registry
          ).to receive(:[]).once.with(StubEntity).and_return repository

          expect(
            repository
          ).to receive(:find_all).once.with(filter: { test_class_id: @subject.id }).and_return []

          expect(@subject.stub_entity).to be_nil
          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil
        end

        it "doesn't call repository when child node is already present" do
          StubEntity.parent_node :test_class

          described_class.child_node :stub_entity

          entity.id = BSON::ObjectId.new
          @subject.instance_variable_set '@stub_entity', entity

          expect(Persisty::Repositories::Registry).not_to receive(:[]).with(any_args)

          expect(@subject.stub_entity).to eql entity
          expect(@subject.instance_variable_get(:@stub_entity)).to eql entity
        end

        it 'resolves parent at child on child node writer, registering previous child to be removed' do
          StubEntity.parent_node :test_class

          previous_child = StubEntity.new(id: BSON::ObjectId.new, test_class: @subject)

          described_class.child_node :stub_entity

          @subject.instance_variable_set '@stub_entity', previous_child

          expect(previous_child).to receive(:test_class_id=).once.with(nil)
          expect(Persisty::Persistence::UnitOfWork).to receive(:current).once.and_return uow
          expect(uow).to receive(:register_removed).once.with(previous_child)

          expect(entity).to receive(:test_class=).once.with(@subject)

          @subject.stub_entity = entity
        end

        it 'resolves parent at child on child node writer, not registering previous nil child' do
          StubEntity.parent_node :test_class
          described_class.child_node :stub_entity

          expect(Persisty::Persistence::UnitOfWork).not_to receive(:current)
          expect(entity).to receive(:test_class=).once.with(@subject)

          @subject.stub_entity = entity
        end

        it "doesn't try to change foreign key on nil child" do
          StubEntity.parent_node :test_class

          described_class.child_node :stub_entity

          expect(Persisty::Persistence::UnitOfWork).not_to receive(:current)

          @subject.stub_entity = nil
        end

        it "doesn't try to change parent on same child as previous" do
          StubEntity.parent_node :test_class

          described_class.child_node :stub_entity

          entity.id = BSON::ObjectId.new
          @subject.instance_variable_set '@stub_entity', entity

          expect(entity).not_to receive(:test_class=).with(any_args)
          expect(Persisty::Persistence::UnitOfWork).not_to receive(:current)

          @subject.stub_entity = entity
        end

        it "doesn't try to remove previous child that doesn't match parent" do
          StubEntity.parent_node :test_class
          described_class.child_node :stub_entity

          another_parent = TestClass.new(id: BSON::ObjectId.new)
          entity.id      = BSON::ObjectId.new
          @subject.instance_variable_set '@stub_entity', entity
          entity.test_class = another_parent

          expect(entity).not_to receive(:test_class=).with(any_args)
          expect(Persisty::Persistence::UnitOfWork).not_to receive(:current)

          @subject.stub_entity = nil
        end

        it 'raises TypeError when trying to assign object of different type' do
          StubEntity.parent_node :test_class

          described_class.child_node :stub_entity

          expect {
            @subject.stub_entity = Object.new
          }.to raise_error(TypeError, "Object is a type mismatch from defined node 'stub_entity'")
        end
      end

      context 'when class_name is present' do
        it 'sets child node field to lazy load object based on class_name' do
          StubEntity.parent_node :test_class

          described_class.child_node :foo, class_name: ::StubEntity

          subject = described_class.new(id: BSON::ObjectId.new)

          expect(subject).to respond_to :foo
          expect(subject).to respond_to(:foo=)
        end

        it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
          expect {
            described_class.child_node :foo, class_name: ::StubEntity
          }.to raise_error(
                 Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                 "Class must have a parent correctly set up. "\
                 "Use parent definition method on child class to set correct parent_node relation."
               )
        end

        it 'performs lazy load on child node reader finding by parent id' do
          StubEntity.parent_node :test_class

          described_class.child_node :foo, class_name: ::StubEntity

          expect(@subject.instance_variable_get(:@foo)).to be_nil

          expect(
            Persisty::Repositories::Registry
          ).to receive(:[]).once.with(StubEntity).and_return repository

          expect(
            repository
          ).to receive(:find_all).once.with(filter: { test_class_id: @subject.id }).and_return [entity]

          expect(@subject.foo).to eql entity
          expect(@subject.instance_variable_get(:@foo)).to eql entity
        end

        it 'returns nil on reader when no child has been found' do
          StubEntity.parent_node :test_class

          described_class.child_node :foo, class_name: StubEntity

          expect(@subject.instance_variable_get(:@foo)).to be_nil

          expect(
            Persisty::Repositories::Registry
          ).to receive(:[]).once.with(StubEntity).and_return repository

          expect(
            repository
          ).to receive(:find_all).once.with(filter: { test_class_id: @subject.id }).and_return []

          expect(@subject.foo).to be_nil
          expect(@subject.instance_variable_get(:@foo)).to be_nil
        end

        it "doesn't call repository when child node is already present" do
          StubEntity.parent_node :test_class

          described_class.child_node :foo, class_name: 'StubEntity'

          entity.id = BSON::ObjectId.new

          @subject.instance_variable_set '@foo', entity

          expect(Persisty::Repositories::Registry).not_to receive(:[]).with(any_args)

          expect(@subject.foo).to eql entity
          expect(@subject.instance_variable_get(:@foo)).to eql entity
        end

        it 'resolves parent at child on child node writer, registering previous child to be removed' do
          StubEntity.parent_node :test_class

          previous_child = StubEntity.new(id: BSON::ObjectId.new, test_class: @subject)

          described_class.child_node :foo, class_name: StubEntity

          @subject.instance_variable_set '@foo', previous_child

          expect(previous_child).to receive(:test_class=).once.with(nil)
          expect(Persisty::Persistence::UnitOfWork).to receive(:current).once.and_return uow
          expect(uow).to receive(:register_removed).once.with(previous_child)
          expect(entity).to receive(:test_class=).once.with(@subject)

          @subject.foo = entity
        end

        it 'resolves parent at child on child node writer, not registering previous nil child' do
          StubEntity.parent_node :test_class
          described_class.child_node :foo, class_name: 'StubEntity'

          expect(Persisty::Persistence::UnitOfWork).not_to receive(:current)
          expect(entity).to receive(:test_class=).once.with(@subject)

          @subject.foo = entity
        end

        it "doesn't try to change foreign key on nil child" do
          StubEntity.parent_node :test_class

          described_class.child_node :foo, class_name: ::StubEntity

          expect(Persisty::Persistence::UnitOfWork).not_to receive(:current)

          @subject.foo = nil
        end

        it "doesn't try to change parent on same child as previous" do
          StubEntity.parent_node :test_class

          described_class.child_node :foo, class_name: StubEntity

          entity.id = BSON::ObjectId.new
          @subject.instance_variable_set '@foo', entity

          expect(entity).not_to receive(:test_class=).with(any_args)
          expect(Persisty::Persistence::UnitOfWork).not_to receive(:current)

          @subject.foo = entity
        end

        it 'raises TypeError when trying to assign object of different type' do
          StubEntity.parent_node :test_class

          described_class.child_node :foo, class_name: 'StubEntity'

          expect {
            @subject.foo = Object.new
          }.to raise_error(TypeError, "Object is a type mismatch from defined node 'foo'")
        end
      end
    end

    context "when foreign_key isn't nil" do
      it 'adds name to child_nodes_map, list and sets accessors' do
        StubEntity.parent_node :foo, class_name: ::TestClass

        described_class.child_node :stub_entity, cascade: true, foreign_key: :foo_id

        expect(@subject).to respond_to :stub_entity
        expect(@subject).to respond_to(:stub_entity=)

        expect(
          described_class.nodes_reference.values
        ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: :foo_id }]))

        expect(
          StubEntity.nodes_reference.values
        ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: :foo_id }]))
      end

      it 'adds name to child_nodes map, even with redundant foreign_key' do
        StubEntity.parent_node :test_class

        described_class.child_node :stub_entity, cascade: true, foreign_key: :test_class_id

        expect(@subject).to respond_to :stub_entity
        expect(@subject).to respond_to(:stub_entity=)

        expect(
          described_class.nodes_reference.values
        ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: :test_class_id }]))

        expect(
          StubEntity.nodes_reference.values
        ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: true, foreign_key: :test_class_id }]))
      end

      it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
        expect {
          described_class.child_node :foo, class_name: 'StubEntity', foreign_key: :foo_id
        }.to raise_error(
               Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
               "Class must have a parent correctly set up. "\
               "Use parent definition method on child class to set correct parent_node relation."
             )
      end

      it "raises NoParentNodeError when child node class doesn't have parent expected" do
        StubEntity.parent_node :test_class

        expect {
          described_class.child_node :foo, class_name: 'StubEntity', foreign_key: :bar_id
        }.to raise_error(
               Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
               "Class must have a parent correctly set up. "\
               "Use parent definition method on child class to set correct parent_node relation."
             )
      end
    end
  end

  describe '.parent_node name, class_name:' do
    before do
      @subject = described_class.new(id: BSON::ObjectId.new)
      Persisty::Persistence::UnitOfWork.new_current
    end

    context 'when it belongs to a parent as part of a collection' do
      let(:current_parent_child_nodes) { double(:child_nodes) }

      context 'when foreign key is same as current' do
        it "doesn't clear parent scope field" do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :stub_entity
          StubEntity.child_nodes :test_classes

          @subject.stub_entity = entity

          expect(entity).not_to receive(:test_classes)

          @subject.stub_entity_id = entity.id
          expect(@subject.instance_variable_get(:@stub_entity)).to eql entity

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end
      end

      context 'when foreign key is nil' do
        it 'removes itself from current_parent collection' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject

          described_class.parent_node :stub_entity
          StubEntity.child_nodes :test_classes
          StubEntity.child_nodes :test_entities, class_name: ::TestClass, foreign_key: :stub_entity_id

          @subject.stub_entity = entity

          expect_any_instance_of(Persisty::Persistence::UnitOfWork).not_to receive(:register_removed)
          expect(entity).to receive(:test_classes).once.and_return current_parent_child_nodes
          expect(current_parent_child_nodes).to receive(:remove).once.with(@subject)
          expect(entity).to receive(:test_entities).once.and_return current_parent_child_nodes
          expect(current_parent_child_nodes).to receive(:remove).once.with(@subject)
          expect(Persisty::Repositories::Registry).not_to receive(:[]).with(any_args)

          @subject.stub_entity_id = nil

          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end
      end

      context 'when foreign key is other' do
        it 'removes itself from current_parent collection, appends itself to new parent collection' do
          entity.id    = BSON::ObjectId.new
          other_parent = StubEntity.new(id: BSON::ObjectId.new)
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :stub_entity
          StubEntity.child_nodes :test_classes

          @subject.stub_entity = entity

          expect_any_instance_of(Persisty::Persistence::UnitOfWork).not_to receive(:register_removed)
          expect(entity).to receive(:test_classes).once.and_return current_parent_child_nodes
          expect(current_parent_child_nodes).to receive(:remove).once.with(@subject)
          expect(Persisty::Repositories::Registry).to receive(:[]).once.with(StubEntity).and_return repository

          expect(
            repository
          ).to receive(:find).once.with(other_parent.id).and_return other_parent

          expect(other_parent).to receive_message_chain(
                                    :test_classes, :push
                                  ).with(@subject)

          @subject.stub_entity_id = other_parent.id

          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end
      end
    end

    context 'when it belongs to a parent as a single child' do
      context 'when class_name is nil' do
        it 'sets parent_node field for its ID and field to lazy load parent' do
          described_class.parent_node :stub_entity

          expect(described_class.fields_list).to include(:stub_entity_id)
          expect(described_class.fields).to include(stub_entity_id: { type: BSON::ObjectId })

          expect(@subject).to respond_to :stub_entity_id
          expect(@subject).to respond_to(:stub_entity_id=)
          expect(@subject).to respond_to :stub_entity
          expect(@subject).to respond_to(:stub_entity=)

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'raises TypeError with custom message on writer when object is a type mismatch' do
          described_class.parent_node :stub_entity

          expect {
            @subject.stub_entity = Object.new
          }.to raise_error(TypeError, "Object is a type mismatch from defined node 'stub_entity'")
        end

        it 'performs lazy load on parent_node reader finding by foreign_key on repository' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject

          described_class.parent_node :stub_entity

          @subject.stub_entity_id = entity.id
          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

          expect(Persisty::Repositories::Registry).to receive(:[]).once.with(StubEntity).and_return repository

          expect(
            repository
          ).to receive(:find).once.with(entity.id).and_return entity

          expect(@subject.stub_entity).to eql entity
          expect(@subject.instance_variable_get(:@stub_entity)).to eql entity

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'sets foreign_key id on foreign_key field from object passed as parent_node on writer' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :stub_entity

          expect {
            @subject.stub_entity = entity

            expect(@subject.stub_entity).to eql entity

            expect(
              Persisty::Persistence::UnitOfWork.current.managed?(@subject)
            ).to be true
          }.to change(@subject, :stub_entity_id).from(nil).to(entity.id)

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'clears foreign key field when entity passed on writer is nil' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :stub_entity
          StubEntity.child_node :test_class

          @subject.stub_entity = entity

          expect {
            @subject.stub_entity = nil

            expect_any_instance_of(Persisty::Persistence::UnitOfWork).not_to receive(:register_removed)
            expect(@subject.stub_entity).to be_nil

            expect(
              Persisty::Persistence::UnitOfWork.current.managed?(@subject)
            ).to be true
          }.to change(@subject, :stub_entity_id).from(entity.id).to(nil)

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'clears parent scope field when foreign key passed is nil' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :stub_entity
          ::StubEntity.child_node :test_class
          @subject.stub_entity = entity

          @subject.stub_entity_id = nil

          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it "doesn't clear parent scope field when foreign key passed is same" do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :stub_entity

          @subject.stub_entity = entity

          @subject.stub_entity_id = entity.id
          expect(@subject.instance_variable_get(:@stub_entity)).to eql entity

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'clears parent scope field when foreign key passed is different' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :stub_entity

          @subject.stub_entity = entity

          @subject.stub_entity_id = BSON::ObjectId.new
          expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'clears child on previous parent when setting foreign_key to nil' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject

          described_class.parent_node :stub_entity
          described_class.parent_node :entity, class_name: 'StubEntity'
          StubEntity.child_node :test_class
          StubEntity.child_node :test_entity, class_name: 'TestClass', foreign_key: :stub_entity_id
          StubEntity.child_node :another_test_class, class_name: 'TestClass', foreign_key: :entity_id

          expect_any_instance_of(
            Persisty::Persistence::UnitOfWork
          ).to receive(:register_removed).once.with(@subject)

          entity.test_class = @subject
          entity.test_entity = @subject
          entity.another_test_class = @subject

          expect(entity.instance_variable_get('@test_class')).not_to be_nil
          expect(entity.instance_variable_get('@test_entity')).not_to be_nil
          expect(entity.instance_variable_get('@another_test_class')).not_to be_nil

          @subject.stub_entity = entity
          @subject.stub_entity_id = nil

          expect(entity.instance_variable_get('@test_class')).to be_nil
          expect(entity.instance_variable_get('@test_entity')).to be_nil
          expect(entity.instance_variable_get('@another_test_class')).not_to be_nil

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'clears child on previous parent without removing its parent when setting foreign_key to other' do
          entity.id    = BSON::ObjectId.new
          other_parent = StubEntity.new(id: BSON::ObjectId.new)
          Persisty::Persistence::UnitOfWork.current.register_clean @subject

          described_class.parent_node :stub_entity
          StubEntity.child_node :test_class

          expect_any_instance_of(
            Persisty::Persistence::UnitOfWork
          ).not_to receive(:register_removed).with(@subject)

          @subject.stub_entity = entity
          @subject.stub_entity_id = other_parent.id

          expect(entity.instance_variable_get('@test_class')).to be_nil

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end

        it 'halts any removing of previous parent on child when trying to set same foreign key' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject

          described_class.parent_node :stub_entity
          StubEntity.child_node :test_class

          expect_any_instance_of(
            Persisty::Persistence::UnitOfWork
          ).not_to receive(:register_removed).with(@subject)

          entity.test_class = @subject
          @subject.stub_entity_id = entity.id

          expect(entity.instance_variable_get('@test_class')).to equal @subject

          expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
        end
      end

      context 'when class_name argument is used' do
        it 'sets parent_node field for its ID and field to lazy load parent' do
          described_class.parent_node :foo, class_name: ::StubEntity

          expect(described_class.fields_list).to include(:foo_id)
          expect(described_class.fields).to include(foo_id: { type: BSON::ObjectId })

          expect(@subject).to respond_to :foo_id
          expect(@subject).to respond_to(:foo_id=)
          expect(@subject).to respond_to :foo
          expect(@subject).to respond_to(:foo=)

          expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
        end

        it 'raises TypeError with custom message on writer when object is a type mismatch' do
          described_class.parent_node :foo, class_name: ::StubEntity

          expect {
            @subject.foo = Object.new
          }.to raise_error(TypeError, "Object is a type mismatch from defined node 'foo'")
        end

        it 'performs lazy load on parent_node reader finding by foreign_key on repository' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject

          described_class.parent_node :foo, class_name: 'StubEntity'

          @subject.foo_id = entity.id
          expect(@subject.instance_variable_get(:@foo)).to be_nil

          expect(
            Persisty::Repositories::Registry
          ).to receive(:[]).once.with(StubEntity).and_return repository

          expect(
            repository
          ).to receive(:find).once.with(entity.id).and_return entity

          expect(@subject.foo).to eql entity
          expect(@subject.instance_variable_get(:@foo)).to eql entity

          expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
        end

        it 'sets foreign_key id on foreign_key field from object passed as parent_node on writer' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :foo, class_name: 'StubEntity'

          expect {
            @subject.foo = entity

            expect(@subject.foo).to eql entity

            expect(
              Persisty::Persistence::UnitOfWork.current.managed?(@subject)
            ).to be true
          }.to change(@subject, :foo_id).from(nil).to(entity.id)

          expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
        end

        it 'clears foreign key field when entity passed on writer is nil' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :foo, class_name: StubEntity

          @subject.foo = entity

          expect {
            @subject.foo = nil

            expect(Persisty::Repositories::Registry).not_to receive(:[]).with(any_args)
            expect(@subject.foo).to be_nil

            expect(
              Persisty::Persistence::UnitOfWork.current.managed?(@subject)
            ).to be true
          }.to change(@subject, :foo_id).from(entity.id).to(nil)

          expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
        end

        it 'clears parent scope field when foreign key passed is nil' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :foo, class_name: StubEntity
          @subject.foo = entity

          @subject.foo_id = nil

          expect(@subject.instance_variable_get(:@foo)).to be_nil

          expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
        end

        it "doesn't clear parent scope field when foreign key passed is same" do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :foo, class_name: StubEntity

          @subject.foo = entity

          @subject.foo_id = entity.id
          expect(@subject.instance_variable_get(:@foo)).to eql entity

          expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
        end

        it 'clears parent scope field when foreign key passed is different' do
          entity.id = BSON::ObjectId.new
          Persisty::Persistence::UnitOfWork.current.register_clean @subject
          described_class.parent_node :foo, class_name: 'StubEntity'

          @subject.foo = entity

          @subject.foo_id = BSON::ObjectId.new
          expect(@subject.instance_variable_get(:@foo)).to be_nil

          expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
          expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
        end
      end
    end
  end
end
