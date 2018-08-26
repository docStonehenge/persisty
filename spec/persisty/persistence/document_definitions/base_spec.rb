module Persisty
  module Persistence
    module DocumentDefinitions
      describe Base do
        include_context 'StubEntity'

        let(:uow) { double(:uow) }
        let!(:id) { BSON::ObjectId.new }
        let(:document_manager) { double(:document_manager) }

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

          context 'associations' do
            describe '.child_node name, class_name:' do
              before do
                @subject = described_class.new(id: BSON::ObjectId.new)
              end

              context 'when class_name is nil' do
                it 'sets child node field to lazy load object' do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(class: described_class)

                  described_class.child_node :stub_entity

                  expect(described_class.child_nodes_list).to include(:stub_entity)
                  expect(described_class.child_nodes_map).to include(stub_entity: ::StubEntity)
                  expect(@subject).to respond_to :stub_entity
                  expect(@subject).to respond_to(:stub_entity=)
                end

                it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
                  allow(StubEntity).to receive(:parent_nodes_map).and_return({})

                  expect {
                    described_class.child_node :stub_entity
                  }.to raise_error(
                         Errors::NoParentNodeError,
                         "Child node class must have a foreign_key field set for parent. "\
                         "Use '.parent_node' method on child class to set correct parent_node relation."
                       )
                end

                it 'performs lazy load on child node reader finding by parent id' do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(class: described_class)

                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new

                  expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

                  expect(DocumentManager).to receive(:new).once.and_return document_manager

                  expect(
                    document_manager
                  ).to receive(:find_all).once.with(
                         StubEntity, filter: { class_id: @subject.id }
                       ).and_return [entity]

                  expect(@subject.stub_entity).to eql entity
                  expect(@subject.instance_variable_get(:@stub_entity)).to eql entity
                end

                it 'returns nil on reader when no child has been found' do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(class: described_class)

                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new

                  expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

                  expect(DocumentManager).to receive(:new).once.and_return document_manager

                  expect(
                    document_manager
                  ).to receive(:find_all).once.with(
                         StubEntity, filter: { class_id: @subject.id }
                       ).and_return []

                  expect(@subject.stub_entity).to be_nil
                  expect(@subject.instance_variable_get(:@stub_entity)).to be_nil
                end

                it "doesn't call DocumentManager when child node is already present" do
                  StubEntity.parent_node :test_class

                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new
                  entity.id   = BSON::ObjectId.new
                  @subject.instance_variable_set '@stub_entity', entity

                  expect(DocumentManager).not_to receive(:new)

                  expect(@subject.stub_entity).to eql entity
                  expect(@subject.instance_variable_get(:@stub_entity)).to eql entity
                end

                it 'resolves parent at child on child node writer, registering previous child to be removed' do
                  StubEntity.parent_node :test_class

                  previous_child = StubEntity.new(id: BSON::ObjectId.new, test_class: @subject)

                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new
                  @subject.instance_variable_set '@stub_entity', previous_child

                  expect(previous_child).to receive(:test_class_id=).once.with(nil)
                  expect(DocumentManager).to receive(:new).once.and_return document_manager
                  expect(document_manager).to receive(:remove).once.with(previous_child)

                  expect(entity).to receive(:test_class=).once.with(@subject)

                  @subject.stub_entity = entity
                end

                it 'resolves parent at child on child node writer, not registering previous nil child' do
                  StubEntity.parent_node :test_class
                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new

                  expect(DocumentManager).not_to receive(:new)

                  expect(entity).to receive(:test_class=).once.with(@subject)

                  @subject.stub_entity = entity
                end

                it "doesn't try to change foreign key on nil child" do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(test_class: described_class)

                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new

                  expect(DocumentManager).not_to receive(:new)

                  @subject.stub_entity = nil
                end

                it "doesn't try to change parent on same child as previous" do
                  StubEntity.parent_node :test_class

                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new
                  entity.id   = BSON::ObjectId.new
                  @subject.instance_variable_set '@stub_entity', entity

                  expect(entity).not_to receive(:test_class=).with(any_args)
                  expect(DocumentManager).not_to receive(:new)

                  @subject.stub_entity = entity
                end

                it "doesn't try to remove previous child that doesn't match parent" do
                  StubEntity.parent_node :test_class
                  described_class.child_node :stub_entity

                  another_parent = TestClass.new(id: BSON::ObjectId.new)
                  @subject.id = BSON::ObjectId.new
                  entity.id   = BSON::ObjectId.new
                  @subject.instance_variable_set '@stub_entity', entity
                  entity.test_class = another_parent

                  expect(entity).not_to receive(:test_class=).with(any_args)
                  expect(DocumentManager).not_to receive(:new)

                  @subject.stub_entity = nil
                end

                it 'raises TypeError when trying to assign object of different type' do
                  StubEntity.parent_node :test_class

                  described_class.child_node :stub_entity

                  @subject.id = BSON::ObjectId.new

                  expect {
                    @subject.stub_entity = Object.new
                  }.to raise_error(TypeError, "Object is a type mismatch from defined node 'stub_entity'")
                end
              end

              context 'when class_name is present' do
                it 'sets child node field to lazy load object based on class_name' do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(parent_name: described_class)

                  described_class.child_node :foo, class_name: ::StubEntity

                  subject = described_class.new(id: BSON::ObjectId.new)

                  expect(described_class.child_nodes_list).to include(:foo)
                  expect(described_class.child_nodes_map).to include(foo: ::StubEntity)
                  expect(subject).to respond_to :foo
                  expect(subject).to respond_to(:foo=)
                end

                it "raises NoParentNodeError when child node class doesn't have parent foreign keys field" do
                  allow(StubEntity).to receive(:parent_nodes_map).and_return({})

                  expect {
                    described_class.child_node :foo, class_name: ::StubEntity
                  }.to raise_error(
                         Errors::NoParentNodeError,
                         "Child node class must have a foreign_key field set for parent. "\
                         "Use '.parent_node' method on child class to set correct parent_node relation."
                       )
                end

                it 'performs lazy load on child node reader finding by parent id' do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(parent_name: described_class)

                  described_class.child_node :foo, class_name: ::StubEntity

                  @subject.id = BSON::ObjectId.new

                  expect(@subject.instance_variable_get(:@foo)).to be_nil

                  expect(DocumentManager).to receive(:new).once.and_return document_manager

                  expect(
                    document_manager
                  ).to receive(:find_all).once.with(
                         StubEntity, filter: { parent_name_id: @subject.id }
                       ).and_return [entity]

                  expect(@subject.foo).to eql entity
                  expect(@subject.instance_variable_get(:@foo)).to eql entity
                end

                it 'returns nil on reader when no child has been found' do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(class: described_class)

                  described_class.child_node :foo, class_name: StubEntity

                  @subject.id = BSON::ObjectId.new

                  expect(@subject.instance_variable_get(:@foo)).to be_nil

                  expect(DocumentManager).to receive(:new).once.and_return document_manager

                  expect(
                    document_manager
                  ).to receive(:find_all).once.with(
                         StubEntity, filter: { class_id: @subject.id }
                       ).and_return []

                  expect(@subject.foo).to be_nil
                  expect(@subject.instance_variable_get(:@foo)).to be_nil
                end

                it "doesn't call DocumentManager when child node is already present" do
                  StubEntity.parent_node :test_class

                  described_class.child_node :foo, class_name: 'StubEntity'

                  @subject.id = BSON::ObjectId.new
                  entity.id   = BSON::ObjectId.new

                  @subject.instance_variable_set '@foo', entity

                  expect(DocumentManager).not_to receive(:new)

                  expect(@subject.foo).to eql entity
                  expect(@subject.instance_variable_get(:@foo)).to eql entity
                end

                it 'resolves parent at child on child node writer, registering previous child to be removed' do
                  StubEntity.parent_node :test_class

                  previous_child = StubEntity.new(id: BSON::ObjectId.new, test_class: @subject)

                  described_class.child_node :foo, class_name: StubEntity

                  @subject.id = BSON::ObjectId.new
                  @subject.instance_variable_set '@foo', previous_child

                  expect(previous_child).to receive(:test_class=).once.with(nil)
                  expect(DocumentManager).to receive(:new).once.and_return document_manager
                  expect(document_manager).to receive(:remove).once.with(previous_child)

                  expect(entity).to receive(:test_class=).once.with(@subject)

                  @subject.foo = entity
                end

                it 'resolves parent at child on child node writer, not registering previous nil child' do
                  StubEntity.parent_node :test_class
                  described_class.child_node :foo, class_name: 'StubEntity'

                  @subject.id = BSON::ObjectId.new

                  expect(DocumentManager).not_to receive(:new)

                  expect(entity).to receive(:test_class=).once.with(@subject)

                  @subject.foo = entity
                end

                it "doesn't try to change foreign key on nil child" do
                  allow(StubEntity).to receive(
                                         :parent_nodes_map
                                       ).and_return(test_class: described_class)

                  described_class.child_node :foo, class_name: ::StubEntity

                  @subject.id = BSON::ObjectId.new

                  expect(DocumentManager).not_to receive(:new)

                  @subject.foo = nil
                end

                it "doesn't try to change parent on same child as previous" do
                  StubEntity.parent_node :test_class

                  described_class.child_node :foo, class_name: StubEntity

                  @subject.id = BSON::ObjectId.new
                  entity.id   = BSON::ObjectId.new
                  @subject.instance_variable_set '@foo', entity

                  expect(entity).not_to receive(:test_class=).with(any_args)
                  expect(DocumentManager).not_to receive(:new)

                  @subject.foo = entity
                end

                it 'raises TypeError when trying to assign object of different type' do
                  StubEntity.parent_node :test_class

                  described_class.child_node :foo, class_name: 'StubEntity'

                  @subject.id = BSON::ObjectId.new

                  expect {
                    @subject.foo = Object.new
                  }.to raise_error(TypeError, "Object is a type mismatch from defined node 'foo'")
                end
              end
            end

            describe '.parent_node name, class_name:' do
              before do
                @subject = described_class.new(id: BSON::ObjectId.new)
                Persistence::UnitOfWork.new_current
              end

              context 'when class_name is nil' do
                it 'sets parent_node field for its ID and field to lazy load parent' do
                  described_class.parent_node :string

                  expect(described_class.parent_nodes_list).to include(:string)
                  expect(described_class.parent_nodes_map).to include(string: String)

                  expect(described_class.fields_list).to include(:string_id)
                  expect(described_class.fields).to include(string_id: { type: BSON::ObjectId })

                  expect(@subject).to respond_to :string_id
                  expect(@subject).to respond_to(:string_id=)
                  expect(@subject).to respond_to :string
                  expect(@subject).to respond_to(:string=)
                end

                it 'raises TypeError with custom message on writer when object is a type mismatch' do
                  described_class.parent_node :string

                  expect {
                    @subject.string = Object.new
                  }.to raise_error(TypeError, "Object is a type mismatch from defined node 'string'")
                end

                it 'performs lazy load on parent_node reader finding by foreign_key on repository' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject

                  described_class.parent_node :stub_entity

                  @subject.stub_entity_id = entity.id
                  expect(@subject.instance_variable_get(:@stub_entity)).to be_nil

                  expect(DocumentManager).to receive(:new).once.and_return document_manager

                  expect(
                    document_manager
                  ).to receive(:find).once.with(StubEntity, entity.id).and_return entity

                  expect(@subject.stub_entity).to eql entity
                  expect(@subject.instance_variable_get(:@stub_entity)).to eql entity
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
                end

                it 'clears foreign key field when entity passed on writer is nil' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :stub_entity

                  @subject.stub_entity = entity

                  expect {
                    @subject.stub_entity = nil

                    expect(DocumentManager).not_to receive(:new)
                    expect(@subject.stub_entity).to be_nil

                    expect(
                      Persistence::UnitOfWork.current.managed?(@subject)
                    ).to be true
                  }.to change(@subject, :stub_entity_id).from(entity.id).to(nil)
                end

                it 'clears parent scope field when foreign key passed is nil' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :stub_entity
                  ::StubEntity.child_node :test_class
                  @subject.stub_entity = entity

                  @subject.stub_entity_id = nil

                  expect(@subject.instance_variable_get(:@stub_entity)).to be_nil
                end

                it "doesn't clear parent scope field when foreign key passed is same" do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :stub_entity

                  @subject.stub_entity = entity

                  @subject.stub_entity_id = entity.id
                  expect(@subject.instance_variable_get(:@stub_entity)).to eql entity
                end

                it 'clears parent scope field when foreign key passed is different' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :stub_entity

                  @subject.stub_entity = entity

                  @subject.stub_entity_id = BSON::ObjectId.new
                  expect(@subject.instance_variable_get(:@stub_entity)).to be_nil
                end

                it 'clears child on previous parent when setting foreign_key to nil' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject

                  described_class.parent_node :stub_entity
                  StubEntity.child_node :test_class

                  expect(DocumentManager).to receive(:new).once.and_return document_manager
                  expect(document_manager).to receive(:remove).once.with(@subject)

                  entity.test_class = @subject
                  @subject.stub_entity = entity
                  @subject.stub_entity_id = nil

                  expect(entity.instance_variable_get('@test_class')).to be_nil
                end

                it 'clears child on previous parent without removing its parent when setting foreign_key to other' do
                  entity.id    = BSON::ObjectId.new
                  other_parent = StubEntity.new(id: BSON::ObjectId.new)
                  Persistence::UnitOfWork.current.register_clean @subject

                  described_class.parent_node :stub_entity
                  StubEntity.child_node :test_class

                  expect_any_instance_of(DocumentManager).not_to receive(:remove).with(@subject)

                  @subject.stub_entity = entity
                  @subject.stub_entity_id = other_parent.id

                  expect(entity.instance_variable_get('@test_class')).to be_nil
                end

                it 'halts any removing of previous parent on child when trying to set same foreign key' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject

                  described_class.parent_node :stub_entity
                  StubEntity.child_node :test_class

                  expect_any_instance_of(DocumentManager).not_to receive(:remove).with(@subject)

                  entity.test_class = @subject
                  @subject.stub_entity_id = entity.id

                  expect(entity.instance_variable_get('@test_class')).to equal @subject
                end
              end

              context 'when class_name argument is used' do
                it 'sets parent_node field for its ID and field to lazy load parent' do
                  described_class.parent_node :foo, class_name: String

                  expect(described_class.parent_nodes_list).to include(:foo)
                  expect(described_class.parent_nodes_map).to include(foo: String)

                  expect(described_class.fields_list).to include(:foo_id)
                  expect(described_class.fields).to include(foo_id: { type: BSON::ObjectId })

                  expect(@subject).to respond_to :foo_id
                  expect(@subject).to respond_to(:foo_id=)
                  expect(@subject).to respond_to :foo
                  expect(@subject).to respond_to(:foo=)
                end

                it 'raises TypeError with custom message on writer when object is a type mismatch' do
                  described_class.parent_node :foo, class_name: String

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

                  expect(DocumentManager).to receive(:new).once.and_return document_manager

                  expect(
                    document_manager
                  ).to receive(:find).once.with(StubEntity, entity.id).and_return entity

                  expect(@subject.foo).to eql entity
                  expect(@subject.instance_variable_get(:@foo)).to eql entity
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
                end

                it 'clears foreign key field when entity passed on writer is nil' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :foo, class_name: StubEntity

                  @subject.foo = entity

                  expect {
                    @subject.foo = nil

                    expect(DocumentManager).not_to receive(:new)
                    expect(@subject.foo).to be_nil

                    expect(
                      Persistence::UnitOfWork.current.managed?(@subject)
                    ).to be true
                  }.to change(@subject, :foo_id).from(entity.id).to(nil)
                end

                it 'clears parent scope field when foreign key passed is nil' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :foo, class_name: StubEntity
                  @subject.foo = entity

                  @subject.foo_id = nil

                  expect(@subject.instance_variable_get(:@foo)).to be_nil
                end

                it "doesn't clear parent scope field when foreign key passed is same" do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :foo, class_name: StubEntity

                  @subject.foo = entity

                  @subject.foo_id = entity.id
                  expect(@subject.instance_variable_get(:@foo)).to eql entity
                end

                it 'clears parent scope field when foreign key passed is different' do
                  entity.id = BSON::ObjectId.new
                  Persistence::UnitOfWork.current.register_clean @subject
                  described_class.parent_node :foo, class_name: 'StubEntity'

                  @subject.foo = entity

                  @subject.foo_id = BSON::ObjectId.new
                  expect(@subject.instance_variable_get(:@foo)).to be_nil
                end
              end
            end
          end

          context 'attributes' do
            describe '.define_field name, type:' do
              context 'when field is ID' do
                context 'when entity is handled by current UnitOfWork' do
                  before do
                    @subject = described_class.new(id: BSON::ObjectId.new)
                    Persistence::UnitOfWork.new_current
                    Persistence::UnitOfWork.current.register_clean @subject
                  end

                  it 'defines reader and writer for field, and writer will raise ArgumentError' do
                    expect(described_class.fields_list).to include(:id)
                    expect(described_class.fields).to include(id: { type: BSON::ObjectId })

                    expect(@subject).to respond_to :id
                    expect(@subject).to respond_to(:id=)

                    expect {
                      expect {
                        @subject.id = BSON::ObjectId.new
                      }.to raise_error(ArgumentError, 'Cannot change ID from an entity that is still on current UnitOfWork')
                    }.not_to change(@subject, :id)
                  end
                end

                context "when entity isn't handled by current UnitOfWork" do
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

                context "when UnitOfWork isn't started" do
                  before do
                    @subject = described_class.new
                    Persistence::UnitOfWork.current = nil
                  end

                  it 'defines reader and writer for field, allows setting id correctly' do
                    expect(described_class.fields_list).to include(:id)
                    expect(described_class.fields).to include(id: { type: BSON::ObjectId })

                    expect(@subject).to respond_to :id
                    expect(@subject).to respond_to(:id=)

                    new_id = BSON::ObjectId.new

                    expect { @subject.id = new_id }.to change(@subject, :id).to(new_id)
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

                  it 'defines reader, writer, converting field and registering object into UnitOfWork' do
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

                  it 'defines reader and writer for field; writer does not register on UnitOfWork' do
                    expect {
                      expect(
                        Persistence::UnitOfWork.current
                      ).not_to receive(:register_changed).with(any_args)

                      @subject.name = 'New name'
                    }.not_to change(@subject, :name)
                  end
                end

                context 'when current UnitOfWork is not started' do
                  before do
                    @subject = described_class.new(id: BSON::ObjectId.new, name: 'Name')
                    Persistence::UnitOfWork.current = nil
                    expect(@subject).to respond_to :name
                    expect(@subject).to respond_to(:name=)
                  end

                  it 'defines reader, writer, converting field only' do
                    expect {
                      @subject.name = 'New name'
                    }.to change(@subject, :name).to('New name')
                  end
                end
              end
            end
          end
        end

        describe 'InstanceMethods' do
          class ::TestEntity
            include Base

            parent_node :stub_entity

            define_field :first_name, type: String
            define_field :dob,        type: Date
          end

          let(:described_class) { ::TestEntity }

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

          describe '#child_nodes_list' do
            it 'returns list of child_nodes set on object class' do
              StubEntity.child_node :test_entity

              subject = StubEntity.new

              expect(subject.child_nodes_list).to include :test_entity
            end
          end

          describe '#child_nodes_map' do
            it 'returns map of child_nodes on object class' do
              StubEntity.child_node :test_entity

              subject = StubEntity.new

              expect(subject.child_nodes_map).to include(test_entity: ::TestEntity)
            end
          end

          context 'can be initialized with any atributes' do
            it 'can be initialized without any attributes' do
              subject = described_class.new

              expect(subject.id).to be_nil
              expect(subject.first_name).to be_nil
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

            context 'when subject has no id' do
              before { allow(subject).to receive(:id).and_return nil }

              it 'raises comparison error on less than' do
                expect {
                  subject < described_class.new(id: id, first_name: 'John', dob: Date.parse('1990/01/01'))
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
              end

              it 'raises comparison error on greater than' do
                expect {
                  subject > described_class.new(id: id, first_name: 'John', dob: Date.parse('1990/01/01'))
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
              end

              it 'raises comparison error on less than or equal' do
                expect {
                  subject <= described_class.new(id: id, first_name: 'John', dob: Date.parse('1990/01/01'))
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
              end

              it 'raises comparison error on greater than or equal' do
                expect {
                  subject >= described_class.new(id: id, first_name: 'John', dob: Date.parse('1990/01/01'))
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
              end
            end

            context 'when other object has no id' do
              before do
                @other_entity = described_class.new(
                  first_name: 'John', dob: Date.parse('1990/01/01')
                )
              end

              it 'raises comparison error on less than' do
                expect {
                  subject < @other_entity
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
              end

              it 'raises comparison error on greater than' do
                expect {
                  subject > @other_entity
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
              end

              it 'raises comparison error on less than or equal' do
                expect {
                  subject <= @other_entity
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
              end

              it 'raises comparison error on greater than or equal' do
                expect {
                  subject >= @other_entity
                }.to raise_error(
                       Entities::ComparisonError, "Cannot compare with an entity that isn't persisted."
                     )
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

          describe '#to_hash include_id_field: true' do
            subject { described_class.new(id: id, first_name: 'John', dob: Date.parse('1990/01/01')) }

            before do
              entity.id = BSON::ObjectId.new
              described_class.parent_node :entity, class_name: entity.class
              subject.entity = entity
            end

            context 'when ID field is included' do
              it 'returns fields names and values mapped into a Hash, without relations' do
                result = subject.to_hash

                expect(result).to include(
                                    id: id, first_name: 'John',
                                    dob: Date.parse('1990/01/01'), entity_id: entity.id
                                  )

                expect(result).not_to have_key(:entity)
              end
            end

            context 'when ID field is not included' do
              it 'returns fields names and values mapped into a Hash, without relations and ID' do
                result = subject.to_hash(include_id_field: false)

                expect(result).to include(
                                    first_name: 'John', dob: Date.parse('1990/01/01'),
                                    entity_id: entity.id
                                  )

                expect(result).not_to have_key(:entity)
              end
            end
          end

          describe '#to_mongo_document' do
            include_context 'EntityWithAllValues'

            subject do
              EntityWithAllValues.new(
                id: id, field1: "Foo", field2: 123, field3: 123.0,
                field4: BigDecimal.new("123.0"), field5: true,
                field6: [123, BigDecimal.new("200")],
                field7: { foo: Date.parse("01/01/1990"), 'bazz' => BigDecimal.new(400) },
                field8: id, field9: Date.parse('01/01/1990'),
                field10: DateTime.new(2017, 11, 21), field11: Time.new(2017, 11, 21)
              )
            end

            before do
              entity.id = BSON::ObjectId.new
              subject.test_scope = entity
            end

            it "maps fields names and values, with mongo permitted values and '_id' field" do
              expect(
                subject.to_mongo_document
              ).to eql(
                     _id: id, field1: "Foo", field2: 123, field3: 123.0,
                     field4: 123.0, field5: true, field6: [123, 200.0],
                     field7: { foo: Date.parse("01/01/1990"), 'bazz' => 400.0 },
                     field8: id, field9: Date.parse('01/01/1990'),
                     field10: DateTime.new(2017, 11, 21),
                     field11: Time.new(2017, 11, 21), test_scope_id: entity.id
                   )
            end

            it "maps fields names and values, with mongo permitted values, without '_id' field" do
              expect(
                subject.to_mongo_document(include_id_field: false)
              ).to eql(
                     field1: "Foo", field2: 123, field3: 123.0, field4: 123.0,
                     field5: true, field6: [123, 200.0],
                     field7: { foo: Date.parse("01/01/1990"), 'bazz' => 400.0 },
                     field8: id, field9: Date.parse('01/01/1990'),
                     field10: DateTime.new(2017, 11, 21),
                     field11: Time.new(2017, 11, 21), test_scope_id: entity.id
                   )
            end
          end
        end
      end
    end
  end
end
