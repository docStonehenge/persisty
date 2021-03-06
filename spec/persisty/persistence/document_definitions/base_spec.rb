module Persisty
  module Persistence
    module DocumentDefinitions
      describe Base do
        include_context 'StubEntity'

        after do
          ObjectSpace.each_object(NodesReference).each do |ref|
            ref.instance_variable_get(:@nodes).clear
          end
        end

        let(:uow) { double(:uow) }
        let!(:id) { BSON::ObjectId.new }
        let(:repository) { double(:repository) }

        describe 'ClassMethods' do
          class ::TestClass
            include Base
          end

          let(:described_class) { TestClass }

          it 'defines ID field' do
            expect(described_class.new).to have_id_defined
          end

          describe '.repository' do
            it 'raises NotImplementedError' do
              expect {
                described_class.repository
              }.to raise_error(NotImplementedError)
            end
          end

          it '.nodes_reference' do
            expect(described_class.nodes_reference).to be_an_instance_of(NodesReference)
          end

          context 'associations' do
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
                           Errors::NoParentNodeError,
                           "Child node class must have a foreign_key field set for parent. "\
                           "Use '.parent_node' method on child class to set correct parent_node relation."
                         )
                  end

                  it "raises NoParentNodeError when child node class doesn't have parent expected" do
                    StubEntityForCollection.parent_node :foo, class_name: ::TestClass

                    expect {
                      described_class.child_nodes :stub_entity_for_collections
                    }.to raise_error(
                           Errors::NoParentNodeError,
                           "Child node class must have a foreign_key field set for parent. "\
                           "Use '.parent_node' method on child class to set correct parent_node relation."
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

                    expect(DocumentCollectionBuilder).to receive(:new).once.with(
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
                           Errors::NoParentNodeError,
                           "Child node class must have a foreign_key field set for parent. "\
                           "Use '.parent_node' method on child class to set correct parent_node relation."
                         )
                  end

                  it "raises NoParentNodeError when child node class doesn't have parent expected" do
                    StubEntityForCollection.parent_node :foo, class_name: ::TestClass

                    expect {
                      described_class.child_nodes :foos, class_name: 'StubEntityForCollection'
                    }.to raise_error(
                           Errors::NoParentNodeError,
                           "Child node class must have a foreign_key field set for parent. "\
                           "Use '.parent_node' method on child class to set correct parent_node relation."
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

                    expect(DocumentCollectionBuilder).to receive(:new).once.with(
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
                         Errors::NoParentNodeError,
                         "Child node class must have a foreign_key field set for parent. "\
                         "Use '.parent_node' method on child class to set correct parent_node relation."
                       )
                end

                it "raises NoParentNodeError when child node class doesn't have parent expected" do
                  StubEntityForCollection.parent_node :test_class

                  expect {
                    described_class.child_nodes :foos, class_name: 'StubEntityForCollection', foreign_key: :bar_id
                  }.to raise_error(
                         Errors::NoParentNodeError,
                         "Child node class must have a foreign_key field set for parent. "\
                         "Use '.parent_node' method on child class to set correct parent_node relation."
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
                           Errors::NoParentNodeError,
                           "Child node class must have a foreign_key field set for parent. "\
                           "Use '.parent_node' method on child class to set correct parent_node relation."
                         )
                  end

                  it "raises NoParentNodeError when child node class doesn't have parent expected" do
                    StubEntity.parent_node :foo, class_name: ::TestClass

                    expect {
                      described_class.child_node :stub_entity
                    }.to raise_error(
                           Errors::NoParentNodeError,
                           "Child node class must have a foreign_key field set for parent. "\
                           "Use '.parent_node' method on child class to set correct parent_node relation."
                         )
                  end

                  it 'performs lazy load on child node reader finding by parent id' do
                    StubEntity.parent_node :test_class

                    described_class.child_node :stub_entity

                    expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

                    expect(
                      Repositories::Registry
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
                      Repositories::Registry
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

                    expect(Repositories::Registry).not_to receive(:[]).with(any_args)

                    expect(@subject.stub_entity).to eql entity
                    expect(@subject.instance_variable_get(:@stub_entity)).to eql entity
                  end

                  it 'resolves parent at child on child node writer, registering previous child to be removed' do
                    StubEntity.parent_node :test_class

                    previous_child = StubEntity.new(id: BSON::ObjectId.new, test_class: @subject)

                    described_class.child_node :stub_entity

                    @subject.instance_variable_set '@stub_entity', previous_child

                    expect(previous_child).to receive(:test_class_id=).once.with(nil)
                    expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow
                    expect(uow).to receive(:register_removed).once.with(previous_child)

                    expect(entity).to receive(:test_class=).once.with(@subject)

                    @subject.stub_entity = entity
                  end

                  it 'resolves parent at child on child node writer, not registering previous nil child' do
                    StubEntity.parent_node :test_class
                    described_class.child_node :stub_entity

                    expect(Persistence::UnitOfWork).not_to receive(:current)
                    expect(entity).to receive(:test_class=).once.with(@subject)

                    @subject.stub_entity = entity
                  end

                  it "doesn't try to change foreign key on nil child" do
                    StubEntity.parent_node :test_class

                    described_class.child_node :stub_entity

                    expect(Persistence::UnitOfWork).not_to receive(:current)

                    @subject.stub_entity = nil
                  end

                  it "doesn't try to change parent on same child as previous" do
                    StubEntity.parent_node :test_class

                    described_class.child_node :stub_entity

                    entity.id = BSON::ObjectId.new
                    @subject.instance_variable_set '@stub_entity', entity

                    expect(entity).not_to receive(:test_class=).with(any_args)
                    expect(Persistence::UnitOfWork).not_to receive(:current)

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
                    expect(Persistence::UnitOfWork).not_to receive(:current)

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
                           Errors::NoParentNodeError,
                           "Child node class must have a foreign_key field set for parent. "\
                           "Use '.parent_node' method on child class to set correct parent_node relation."
                         )
                  end

                  it 'performs lazy load on child node reader finding by parent id' do
                    StubEntity.parent_node :test_class

                    described_class.child_node :foo, class_name: ::StubEntity

                    expect(@subject.instance_variable_get(:@foo)).to be_nil

                    expect(
                      Repositories::Registry
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
                      Repositories::Registry
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

                    expect(Repositories::Registry).not_to receive(:[]).with(any_args)

                    expect(@subject.foo).to eql entity
                    expect(@subject.instance_variable_get(:@foo)).to eql entity
                  end

                  it 'resolves parent at child on child node writer, registering previous child to be removed' do
                    StubEntity.parent_node :test_class

                    previous_child = StubEntity.new(id: BSON::ObjectId.new, test_class: @subject)

                    described_class.child_node :foo, class_name: StubEntity

                    @subject.instance_variable_set '@foo', previous_child

                    expect(previous_child).to receive(:test_class=).once.with(nil)
                    expect(Persistence::UnitOfWork).to receive(:current).once.and_return uow
                    expect(uow).to receive(:register_removed).once.with(previous_child)
                    expect(entity).to receive(:test_class=).once.with(@subject)

                    @subject.foo = entity
                  end

                  it 'resolves parent at child on child node writer, not registering previous nil child' do
                    StubEntity.parent_node :test_class
                    described_class.child_node :foo, class_name: 'StubEntity'

                    expect(Persistence::UnitOfWork).not_to receive(:current)
                    expect(entity).to receive(:test_class=).once.with(@subject)

                    @subject.foo = entity
                  end

                  it "doesn't try to change foreign key on nil child" do
                    StubEntity.parent_node :test_class

                    described_class.child_node :foo, class_name: ::StubEntity

                    expect(Persistence::UnitOfWork).not_to receive(:current)

                    @subject.foo = nil
                  end

                  it "doesn't try to change parent on same child as previous" do
                    StubEntity.parent_node :test_class

                    described_class.child_node :foo, class_name: StubEntity

                    entity.id = BSON::ObjectId.new
                    @subject.instance_variable_set '@foo', entity

                    expect(entity).not_to receive(:test_class=).with(any_args)
                    expect(Persistence::UnitOfWork).not_to receive(:current)

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
                         Errors::NoParentNodeError,
                         "Child node class must have a foreign_key field set for parent. "\
                         "Use '.parent_node' method on child class to set correct parent_node relation."
                       )
                end

                it "raises NoParentNodeError when child node class doesn't have parent expected" do
                  StubEntity.parent_node :test_class

                  expect {
                    described_class.child_node :foo, class_name: 'StubEntity', foreign_key: :bar_id
                  }.to raise_error(
                         Errors::NoParentNodeError,
                         "Child node class must have a foreign_key field set for parent. "\
                         "Use '.parent_node' method on child class to set correct parent_node relation."
                       )
                end
              end
            end

            describe '.parent_node name, class_name:' do
              before do
                @subject = described_class.new(id: BSON::ObjectId.new)
                Persistence::UnitOfWork.new_current
              end

              context 'when it belongs to a parent as part of a collection' do
                let(:current_parent_child_nodes) { double(:child_nodes) }

                context 'when foreign key is same as current' do
                  it "doesn't clear parent scope field" do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
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
                    Persistence::UnitOfWork.current.register_clean @subject

                    described_class.parent_node :stub_entity
                    StubEntity.child_nodes :test_classes
                    StubEntity.child_nodes :test_entities, class_name: ::TestClass, foreign_key: :stub_entity_id

                    @subject.stub_entity = entity

                    expect_any_instance_of(Persistence::UnitOfWork).not_to receive(:register_removed)
                    expect(entity).to receive(:test_classes).once.and_return current_parent_child_nodes
                    expect(current_parent_child_nodes).to receive(:remove).once.with(@subject)
                    expect(entity).to receive(:test_entities).once.and_return current_parent_child_nodes
                    expect(current_parent_child_nodes).to receive(:remove).once.with(@subject)
                    expect(Repositories::Registry).not_to receive(:[]).with(any_args)

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
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :stub_entity
                    StubEntity.child_nodes :test_classes

                    @subject.stub_entity = entity

                    expect_any_instance_of(Persistence::UnitOfWork).not_to receive(:register_removed)
                    expect(entity).to receive(:test_classes).once.and_return current_parent_child_nodes
                    expect(current_parent_child_nodes).to receive(:remove).once.with(@subject)
                    expect(Repositories::Registry).to receive(:[]).once.with(StubEntity).and_return repository

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
                    Persistence::UnitOfWork.current.register_clean @subject

                    described_class.parent_node :stub_entity

                    @subject.stub_entity_id = entity.id
                    expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

                    expect(Repositories::Registry).to receive(:[]).once.with(StubEntity).and_return repository

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
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :stub_entity

                    expect {
                      @subject.stub_entity = entity

                      expect(@subject.stub_entity).to eql entity

                      expect(
                        Persistence::UnitOfWork.current.managed?(@subject)
                      ).to be true
                    }.to change(@subject, :stub_entity_id).from(nil).to(entity.id)

                    expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                  end

                  it 'clears foreign key field when entity passed on writer is nil' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :stub_entity
                    StubEntity.child_node :test_class

                    @subject.stub_entity = entity

                    expect {
                      @subject.stub_entity = nil

                      expect_any_instance_of(Persistence::UnitOfWork).not_to receive(:register_removed)
                      expect(@subject.stub_entity).to be_nil

                      expect(
                        Persistence::UnitOfWork.current.managed?(@subject)
                      ).to be true
                    }.to change(@subject, :stub_entity_id).from(entity.id).to(nil)

                    expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                  end

                  it 'clears parent scope field when foreign key passed is nil' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
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
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :stub_entity

                    @subject.stub_entity = entity

                    @subject.stub_entity_id = entity.id
                    expect(@subject.instance_variable_get(:@stub_entity)).to eql entity

                    expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                  end

                  it 'clears parent scope field when foreign key passed is different' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :stub_entity

                    @subject.stub_entity = entity

                    @subject.stub_entity_id = BSON::ObjectId.new
                    expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

                    expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                  end

                  it 'clears child on previous parent when setting foreign_key to nil' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject

                    described_class.parent_node :stub_entity
                    described_class.parent_node :entity, class_name: 'StubEntity'
                    StubEntity.child_node :test_class
                    StubEntity.child_node :test_entity, class_name: 'TestClass', foreign_key: :stub_entity_id
                    StubEntity.child_node :another_test_class, class_name: 'TestClass', foreign_key: :entity_id

                    expect_any_instance_of(
                      Persistence::UnitOfWork
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
                    Persistence::UnitOfWork.current.register_clean @subject

                    described_class.parent_node :stub_entity
                    StubEntity.child_node :test_class

                    expect_any_instance_of(
                      Persistence::UnitOfWork
                    ).not_to receive(:register_removed).with(@subject)

                    @subject.stub_entity = entity
                    @subject.stub_entity_id = other_parent.id

                    expect(entity.instance_variable_get('@test_class')).to be_nil

                    expect(described_class.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                  end

                  it 'halts any removing of previous parent on child when trying to set same foreign key' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject

                    described_class.parent_node :stub_entity
                    StubEntity.child_node :test_class

                    expect_any_instance_of(
                      Persistence::UnitOfWork
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
                    Persistence::UnitOfWork.current.register_clean @subject

                    described_class.parent_node :foo, class_name: 'StubEntity'

                    @subject.foo_id = entity.id
                    expect(@subject.instance_variable_get(:@foo)).to be_nil

                    expect(
                      Repositories::Registry
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
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :foo, class_name: 'StubEntity'

                    expect {
                      @subject.foo = entity

                      expect(@subject.foo).to eql entity

                      expect(
                        Persistence::UnitOfWork.current.managed?(@subject)
                      ).to be true
                    }.to change(@subject, :foo_id).from(nil).to(entity.id)

                    expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                  end

                  it 'clears foreign key field when entity passed on writer is nil' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :foo, class_name: StubEntity

                    @subject.foo = entity

                    expect {
                      @subject.foo = nil

                      expect(Repositories::Registry).not_to receive(:[]).with(any_args)
                      expect(@subject.foo).to be_nil

                      expect(
                        Persistence::UnitOfWork.current.managed?(@subject)
                      ).to be true
                    }.to change(@subject, :foo_id).from(entity.id).to(nil)

                    expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                  end

                  it 'clears parent scope field when foreign key passed is nil' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :foo, class_name: StubEntity
                    @subject.foo = entity

                    @subject.foo_id = nil

                    expect(@subject.instance_variable_get(:@foo)).to be_nil

                    expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                  end

                  it "doesn't clear parent scope field when foreign key passed is same" do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
                    described_class.parent_node :foo, class_name: StubEntity

                    @subject.foo = entity

                    @subject.foo_id = entity.id
                    expect(@subject.instance_variable_get(:@foo)).to eql entity

                    expect(described_class.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                    expect(::StubEntity.nodes_reference).to have_key(node: :foo, class: ::StubEntity)
                  end

                  it 'clears parent scope field when foreign key passed is different' do
                    entity.id = BSON::ObjectId.new
                    Persistence::UnitOfWork.current.register_clean @subject
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

          context 'attributes' do
            describe '.define_field name, type:' do
              context 'when field is ID' do
                context 'when ID is nil' do
                  before do
                    @subject = described_class.new
                    Persistence::UnitOfWork.new_current
                  end

                  it 'defines reader and writer for field, allows setting id correctly' do
                    expect(described_class.fields_list).to include(:id)
                    expect(described_class.fields).to include(id: { type: BSON::ObjectId })

                    expect(@subject).to respond_to :id
                    expect(@subject).to respond_to(:id=)

                    new_id = BSON::ObjectId.new

                    expect { @subject.id = new_id }.to change(@subject, :id).to(new_id)
                    expect(Persistence::UnitOfWork.current.managed?(@subject)).to be false
                  end
                end

                context "when ID isn't nil" do
                  before do
                    @subject = described_class.new(id: BSON::ObjectId.new)
                    Persistence::UnitOfWork.new_current
                  end

                  context 'when new ID is the same as old value' do
                    it 'defines reader and writer for field, and writer sets same value' do
                      expect(described_class.fields_list).to include(:id)
                      expect(described_class.fields).to include(id: { type: BSON::ObjectId })

                      expect(@subject).to respond_to :id
                      expect(@subject).to respond_to(:id=)

                      expect {
                        @subject.id = @subject.id
                      }.not_to change(@subject, :id)
                    end
                  end

                  context "when new ID isn't the same value" do
                    it 'defines reader and writer for field, and writer raises ArgumentError' do
                      expect(described_class.fields_list).to include(:id)
                      expect(described_class.fields).to include(id: { type: BSON::ObjectId })

                      expect(@subject).to respond_to :id
                      expect(@subject).to respond_to(:id=)

                      expect {
                        expect {
                          @subject.id = BSON::ObjectId.new
                        }.not_to change(@subject, :id)
                      }.to raise_error(ArgumentError, 'Cannot change ID when a previous value is already assigned.')
                    end
                  end
                end
              end

              context 'when field is any other than ID' do
                before do
                  described_class.define_field :name, type: String
                  expect(described_class.fields_list).to include(:name)
                  expect(described_class.fields).to include(name: { type: String })
                end

                context 'when value changes' do
                  before do
                    @subject = described_class.new(id: BSON::ObjectId.new)
                    Persistence::UnitOfWork.new_current
                    expect(@subject).to respond_to :name
                    expect(@subject).to respond_to(:name=)
                  end

                  it 'defines reader, writer, converting field, registers object into UnitOfWork' do
                    expect {
                      expect(
                        Persistence::UnitOfWork.current
                      ).to receive(:register_changed).once.with(@subject)

                      @subject.name = 'New name'
                    }.to change(@subject, :name).to('New name')
                  end
                end

                context "when field value doesn't change" do
                  before do
                    @subject = described_class.new(id: BSON::ObjectId.new, name: 'New name')
                    Persistence::UnitOfWork.new_current
                    expect(@subject).to respond_to :name
                    expect(@subject).to respond_to(:name=)
                  end

                  it 'defines reader and writer for field; but still calls UnitOfWork to handle entity' do
                    expect {
                      expect(
                        Persistence::UnitOfWork.current
                      ).to receive(:register_changed).once.with(@subject)

                      @subject.name = 'New name'
                    }.not_to change(@subject, :name)
                  end
                end
              end
            end
          end
        end

        describe 'InstanceMethods' do
          class ::TestEntity
            include Base

            def self.repository
            end

            define_field :first_name, type: String
            define_field :dob,        type: Date
          end

          let(:described_class) { ::TestEntity }

          before do
            described_class.parent_node :stub_entity
          end

          describe '#nodes_reference' do
            it 'returns nodes_reference object set on class' do
              expect(subject.nodes).to equal(described_class.nodes_reference)
            end
          end

          describe '#fields' do
            it 'returns list of fields set on object class' do
              expect(subject.fields).to eql(
                                          id: { type: BSON::ObjectId },
                                          first_name: { type: String },
                                          dob: { type: Date },
                                          stub_entity_id: { type: BSON::ObjectId }
                                        )
            end
          end

          describe '#set_foreign_key_for klass, foreign_key' do
            it 'calls correct writer for klass, assigning foreign_key' do
              expect(subject).to receive(:stub_entity_id=).once.with(123)
              subject.set_foreign_key_for(StubEntity, 123)
            end

            it 'raises NoParentNodeError when no foreign key is set for klass' do
              expect {
                subject.set_foreign_key_for(TestClass, 123)
              }.to raise_error(
                     Errors::NoParentNodeError,
                     "Child node class must have a foreign_key field set for parent. "\
                     "Use '.parent_node' method on child class to set correct parent_node relation."
                   )
            end
          end

          describe '#parent_nodes_list' do
            it 'returns list of parent_nodes set on object class' do
              expect(subject.parent_nodes_list).to include :stub_entity
            end
          end

          describe '#child_node_list' do
            it 'returns list of child_node set on object class' do
              StubEntity.child_node :test_entity, cascade: false
              StubEntity.child_node :fooza, cascade: true, class_name: 'TestEntity', foreign_key: :stub_entity_id

              subject = StubEntity.new

              expect(subject.child_node_list).to contain_exactly :test_entity, :fooza
            end
          end

          describe '#cascading_child_node_objects' do
            it 'returns list of cascading child_objects set on object class' do
              StubEntity.child_node :test_entity
              StubEntity.child_node :fooza, cascade: true, class_name: 'TestEntity', foreign_key: :stub_entity_id

              test_entities = [TestEntity.new, TestEntity.new]
              subject = StubEntity.new
              subject.test_entity = test_entities[0]
              subject.fooza = test_entities[1]

              expect(subject.cascading_child_node_objects).to contain_exactly(test_entities[1])
            end
          end

          describe '#child_nodes_list' do
            it 'returns list of child_nodes collections set on object class' do
              StubEntity.child_nodes :test_entities

              subject = StubEntity.new

              expect(subject.child_nodes_list).to contain_exactly :test_entities
            end
          end

          describe '#cascading_child_nodes_objects' do
            let(:test_entity_collection) { double }

            it 'returns list of cascading child_nodes collections set on object class' do
              StubEntity.child_nodes :test_entities, cascade: true
              StubEntity.child_nodes :tests, class_name: 'TestEntity', cascade: false, foreign_key: :stub_entity_id

              subject = StubEntity.new

              expect(subject).to receive(:test_entities).once.and_return(test_entity_collection)

              expect(
                subject.cascading_child_nodes_objects
              ).to contain_exactly test_entity_collection
            end
          end

          context 'can be initialized with any atributes' do
            it 'can be initialized without any attributes' do
              subject = described_class.new

              expect(subject.id).to be_nil
              expect(subject.first_name).to be_nil
              expect(subject).to have_field_defined :first_name, String
              expect(subject).to have_field_defined :dob, Date
              expect(subject.dob).to be_nil
              expect(subject.stub_entity_id).to be_nil
              expect(subject.stub_entity).to be_nil
            end

            context 'with symbol keys' do
              it 'initializes only with one attribute' do
                subject = described_class.new(first_name: "John")
                expect(subject.first_name).to eql 'John'
                expect(subject.id).to be_nil
                expect(subject.dob).to be_nil
              end

              it 'initializes without ID' do
                subject = described_class.new(first_name: 'John', dob: Date.parse('27/10/1990'))
                expect(subject.id).to be_nil
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it "initializes with id key as '_id'" do
                subject = described_class.new(id: id, first_name: 'John', dob: Date.parse('27/10/1990'))

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it "initializes with id key as 'id'" do
                subject = described_class.new(_id: id, first_name: 'John', dob: Date.parse('27/10/1990'))

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it "initializes with id key as 'id' and '_id'" do
                another_id = BSON::ObjectId.new
                subject = described_class.new(id: id, _id: another_id, first_name: 'John', dob: Date.parse('27/10/1990'))

                expect(subject.id).to eql another_id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it 'initializes with parent node id' do
                entity.id = BSON::ObjectId.new

                subject = described_class.new(
                  id: id, first_name: 'John',
                  dob: Date.parse('27/10/1990'), stub_entity_id: entity.id
                )

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
                expect(subject.stub_entity_id).to eql entity.id
              end

              it 'initializes with parent node object' do
                entity.id = BSON::ObjectId.new

                subject = described_class.new(
                  id: id, first_name: 'John',
                  dob: Date.parse('27/10/1990'), stub_entity: entity
                )

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
                expect(subject.stub_entity).to eql entity
                expect(subject.stub_entity_id).to eql entity.id
              end

              it 'initializes with child node object' do
                StubEntity.child_node :test_entity

                child = described_class.new(id: BSON::ObjectId.new)

                subject = StubEntity.new(id: BSON::ObjectId.new, test_entity: child)

                expect(subject.test_entity).to eql child
              end

              it 'raises error on initialization when parent node object is of wrong type' do
                expect {
                  described_class.new(
                    id: id, first_name: 'John',
                    dob: Date.parse('27/10/1990'), stub_entity: String.new
                  )
                }.to raise_error(TypeError, "Object is a type mismatch from defined node 'stub_entity'")
              end
            end

            context 'with string keys' do
              it 'initializes only with one attribute' do
                subject = described_class.new('first_name' => 'John')
                expect(subject.first_name).to eql 'John'
                expect(subject.id).to be_nil
                expect(subject.dob).to be_nil
              end

              it 'initializes only without ID' do
                subject = described_class.new('first_name' => 'John', 'dob' => Date.parse('27/10/1990'))
                expect(subject.id).to be_nil
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it "initializes with id key as '_id'" do
                subject = described_class.new('_id' => id, 'first_name' => 'John', 'dob' => Date.parse('27/10/1990'))

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it "initializes with id key as 'id'" do
                subject = described_class.new('id' => id, 'first_name' => 'John', 'dob' => Date.parse('27/10/1990'))

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it "initializes with id key as 'id' and '_id'" do
                another_id = BSON::ObjectId.new
                subject = described_class.new('id' => id, '_id' => another_id, 'first_name' => 'John', 'dob' => Date.parse('27/10/1990'))

                expect(subject.id).to eql another_id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
              end

              it 'initializes with parent node id' do
                entity.id = BSON::ObjectId.new

                subject = described_class.new(
                  'id' => id, 'first_name' => 'John',
                  'dob' => Date.parse('27/10/1990'), 'stub_entity_id' => entity.id
                )

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
                expect(subject.stub_entity_id).to eql entity.id
              end

              it 'initializes with parent node object' do
                entity.id = BSON::ObjectId.new

                subject = described_class.new(
                  'id' => id, 'first_name' => 'John',
                  'dob' => Date.parse('27/10/1990'), 'stub_entity' => entity
                )

                expect(subject.id).to eql id
                expect(subject.first_name).to eql 'John'
                expect(subject.dob).to eql Date.parse('27/10/1990')
                expect(subject.stub_entity).to eql entity
                expect(subject.stub_entity_id).to eql entity.id
              end

              it 'initializes with child node object' do
                StubEntity.child_node :test_entity

                child = described_class.new(id: BSON::ObjectId.new)

                subject = StubEntity.new('id' => BSON::ObjectId.new, 'test_entity' => child)

                expect(subject.test_entity).to eql child
              end

              it 'raises error on initialization when parent node object is of wrong type' do
                expect {
                  described_class.new(
                    'id' => id, 'first_name' => 'John',
                    'dob' => Date.parse('27/10/1990'), 'stub_entity' => String.new
                  )
                }.to raise_error(TypeError, "Object is a type mismatch from defined node 'stub_entity'")
              end
            end
          end

          describe '#<=> other' do
            subject { described_class.new(id: id) }

            context 'when other object is from a class different from subject' do
              it 'raises ArgumentError on less than' do
                expect {
                  subject < StubEntity.new
                }.to raise_error(ArgumentError)
              end

              it 'raises ArgumentError on greater than' do
                expect {
                  subject > StubEntity.new
                }.to raise_error(ArgumentError)
              end

              it 'is false on less than or equal' do
                expect(subject).not_to be <= StubEntity.new
              end

              it 'is false on greater than or equal' do
                expect(subject).not_to be >= StubEntity.new
              end
            end

            context 'when subject has no id' do
              let(:other_entity) { described_class.new(id: id, first_name: 'John', dob: Date.parse('1990/01/01')) }

              before { allow(subject).to receive(:id).and_return nil }

              it 'compares with other entity by object_id' do
                expect(subject).not_to be == other_entity
                expect(subject).to be == subject
              end
            end

            context 'when other object has no id' do
              let(:other_entity) { described_class.new(first_name: 'John', dob: Date.parse('1990/01/01')) }

              it 'compares with other entity by object_id' do
                expect(subject).not_to be == other_entity
                expect(subject).to be == subject
              end
            end

            it 'compares less than with other entity by id' do
              expect(
                subject
              ).to be < described_class.new(id: BSON::ObjectId.new, first_name: 'John', dob: Date.parse('1990/01/01'))
            end

            it 'compares greater than with other entity by id' do
              another_entity = described_class.new(id: BSON::ObjectId.new, first_name: 'John', dob: Date.parse('1990/01/01'))
              expect(subject).to be > another_entity
            end

            it 'compares less than or equal to with other entity by id' do
              expect(
                subject
              ).to be <= described_class.new(id: BSON::ObjectId.new, first_name: 'John', dob: Date.parse('1990/01/01'))
            end

            it 'compares greater than or equal to with other entity by id' do
              another_entity = described_class.new(id: BSON::ObjectId.new, first_name: 'John', dob: Date.parse('1990/01/01'))
              expect(subject).to be >= another_entity
            end
          end

          describe '#_raw_fields include_id_field: true' do
            subject { described_class.new(id: id, first_name: 'John', dob: Date.parse('1990/01/01')) }

            before do
              entity.id = BSON::ObjectId.new
              subject.stub_entity = entity
            end

            context 'when ID field is included' do
              it 'returns fields names and values mapped into a Hash, without relations' do
                result = subject._raw_fields

                expect(result).to include(
                                    id: id, first_name: 'John',
                                    dob: Date.parse('1990/01/01'), stub_entity_id: entity.id
                                  )

                expect(result).not_to have_key(:stub_entity)
              end
            end

            context 'when ID field is not included' do
              it 'returns fields names and values mapped into a Hash, without relations and ID' do
                result = subject._raw_fields(include_id_field: false)

                expect(result).to include(
                                    first_name: 'John', dob: Date.parse('1990/01/01'),
                                    stub_entity_id: entity.id
                                  )

                expect(result).not_to have_key(:stub_entity)
              end
            end
          end

          describe '#_as_mongo_document' do
            include_context 'EntityWithAllValues'

            subject do
              EntityWithAllValues.new(
                id: id, field1: "Foo", field2: 123, field3: 123.0,
                field4: BigDecimal("123.0"), field5: true,
                field6: [123, BigDecimal("200")],
                field7: { foo: Date.parse("01/01/1990"), 'bazz' => BigDecimal(400) },
                field8: id, field9: Date.parse('01/01/1990'),
                field10: DateTime.new(2017, 11, 21), field11: Time.new(2017, 11, 21)
              )
            end

            before do
              @id = BSON::ObjectId.new
              EntityWithAllValues.parent_node :test_scope, class_name: ::ParentEntity
              subject.test_scope = ParentEntity.new(id: @id)
            end

            it "maps fields names and values, with mongo permitted values and '_id' field" do
              expect(
                subject._as_mongo_document
              ).to eql(
                     _id: id, field1: "Foo", field2: 123, field3: 123.0,
                     field4: 123.0, field5: true, field6: [123, 200.0],
                     field7: { foo: Date.parse("01/01/1990"), 'bazz' => 400.0 },
                     field8: id, field9: Date.parse('01/01/1990'),
                     field10: DateTime.new(2017, 11, 21),
                     field11: Time.new(2017, 11, 21), test_scope_id: @id
                   )
            end

            it "maps fields names and values, with mongo permitted values, without '_id' field" do
              expect(
                subject._as_mongo_document(include_id_field: false)
              ).to eql(
                     field1: "Foo", field2: 123, field3: 123.0, field4: 123.0,
                     field5: true, field6: [123, 200.0],
                     field7: { foo: Date.parse("01/01/1990"), 'bazz' => 400.0 },
                     field8: id, field9: Date.parse('01/01/1990'),
                     field10: DateTime.new(2017, 11, 21),
                     field11: Time.new(2017, 11, 21), test_scope_id: @id
                   )
            end
          end
        end
      end
    end
  end
end
