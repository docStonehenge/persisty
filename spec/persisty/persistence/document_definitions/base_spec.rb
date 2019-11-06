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
            it_behaves_like 'entity associations methods'

            describe '.embedding_parent name, class_name:' do
              before do
                @subject = described_class.new(id: BSON::ObjectId.new)
              end

              it 'maps parent reference to a NodesReference object and sets accessors' do
                described_class.embedding_parent :stub_entity

                expect(@subject).to respond_to(:stub_entity)
                expect(@subject).to respond_to(:stub_entity=)

                parent = StubEntity.new

                @subject.stub_entity = parent

                expect(@subject.stub_entity).to eql parent

                expect(described_class.embedding_reference).to have_key(node: :stub_entity, class: ::StubEntity)
                expect(::StubEntity.embedding_reference).to have_key(node: :stub_entity, class: ::StubEntity)
              end

              it 'raises TypeError with custom message on writer when object is a type mismatch' do
                described_class.embedding_parent :foo, class_name: StubEntity

                expect(@subject).to respond_to(:foo)
                expect(@subject).to respond_to(:foo=)

                expect(described_class.embedding_reference).to have_key(node: :foo, class: ::StubEntity)
                expect(::StubEntity.embedding_reference).to have_key(node: :foo, class: ::StubEntity)

                expect {
                  @subject.foo = Object.new
                }.to raise_error(TypeError, "Object is a type mismatch from defined node 'foo'")
              end

              context 'when embedding_parent has embedded child set' do
                context 'when assigning a different parent from previous' do
                  it 'clears child from previous parent, sets it in new parent and mark both as changed' do
                    described_class.embedding_parent :stub_entity
                    StubEntity.embed_child :test_class

                    parent1 = StubEntity.new
                    parent2 = StubEntity.new

                    @subject.stub_entity = parent1
                    expect(@subject.stub_entity).to eql parent1
                    expect(parent1.test_class).to eql @subject

                    allow(Persistence::UnitOfWork).to receive(:current).and_return uow
                    expect(uow).to receive(:register_changed).once.with(parent1)
                    expect(uow).to receive(:register_changed).once.with(parent2)

                    @subject.stub_entity = parent2
                    expect(@subject.stub_entity).to eql parent2
                    expect(parent1.test_class).to be_nil
                    expect(parent2.test_class).to eql @subject
                  end
                end

                context 'when assigning nil to clear current_parent' do
                  it 'clears child from previous parent and marks previous parent as changed' do
                    described_class.embedding_parent :stub_entity
                    StubEntity.embed_child :test_class

                    parent = StubEntity.new
                    @subject.stub_entity = parent
                    expect(@subject.stub_entity).to eql parent
                    expect(parent.test_class).to eql @subject

                    allow(Persistence::UnitOfWork).to receive(:current).and_return uow
                    expect(uow).to receive(:register_changed).once.with(parent)

                    @subject.stub_entity = nil

                    expect(@subject.stub_entity).to be_nil
                    expect(parent.test_class).to be_nil
                  end
                end

                context 'when assigning same parent as before' do
                  it 'halts execution' do
                    described_class.embedding_parent :stub_entity
                    StubEntity.embed_child :test_class

                    parent = StubEntity.new
                    @subject.stub_entity = parent
                    expect(@subject.stub_entity).to eql parent
                    expect(parent.test_class).to eql @subject

                    expect_any_instance_of(
                      Persistence::UnitOfWork
                    ).not_to receive(:register_changed).with(parent)

                    @subject.stub_entity = parent
                    expect(@subject.stub_entity).to eql parent
                    expect(parent.test_class).to eql @subject
                  end
                end
              end
            end

            describe '.embed_child name, class_name:, embedding_parent:' do
              before do
                @subject = described_class.new(id: BSON::ObjectId.new)
              end

              it 'maps reference and defines accessors for child' do
                StubEntity.embedding_parent :test_class
                described_class.embed_child :stub_entity

                expect(@subject).to respond_to(:stub_entity)
                expect(@subject).to respond_to(:stub_entity=)

                expect(
                  described_class.embedding_reference.values
                ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil }]))

                expect(
                  StubEntity.embedding_reference.values
                ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil }]))
              end

              it 'maps correct embedding parent when its name is different from its class' do
                StubEntity.embedding_parent :foo, class_name: TestClass
                described_class.embed_child :stub_entity, embedding_parent: :foo

                expect(@subject).to respond_to(:stub_entity)
                expect(@subject).to respond_to(:stub_entity=)

                expect(
                  described_class.embedding_reference.values
                ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil }]))

                expect(
                  StubEntity.embedding_reference.values
                ).to include(a_hash_including(child_node: [{ node: :stub_entity, class: ::StubEntity, cascade: false, foreign_key: nil }]))
              end

              it "raises NoParentNodeError when embedded child class doesn't have embedding_parent" do
                expect {
                  described_class.embed_child :stub_entity
                }.to raise_error(
                       Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                       "Class must have a parent correctly set up. "\
                       "Use parent definition method on child class to set correct parent_node relation."
                     )
              end

              it "raises NoParentNodeError when embedded child class doesn't have parent expected" do
                StubEntity.embedding_parent :foo, class_name: ::TestClass

                expect {
                  described_class.embed_child :stub_entity
                }.to raise_error(
                       Persisty::Persistence::DocumentDefinitions::Errors::NoParentNodeError,
                       "Class must have a parent correctly set up. "\
                       "Use parent definition method on child class to set correct parent_node relation."
                     )
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
            it 'returns list of cascading child_objects set on object class with their foreign keys' do
              StubEntity.child_node :test_entity
              StubEntity.child_node :fooza, cascade: true, class_name: 'TestEntity', foreign_key: :stub_entity_id

              test_entities = [TestEntity.new, TestEntity.new]
              subject = StubEntity.new
              subject.test_entity = test_entities[0]
              subject.fooza = test_entities[1]

              expect(subject.cascading_child_node_objects).to contain_exactly([test_entities[1], :stub_entity_id])
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
              ).to contain_exactly [test_entity_collection, :stub_entity_id]
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

          describe '#assign_foreign_key foreign_key_name, id' do
            it 'assigns id correctly to foreign_key field with foreign_key_name' do
              id = BSON::ObjectId.new
              subject.assign_foreign_key :stub_entity_id, id
              expect(subject.stub_entity_id).to eql id
            end

            it "raises error when foreign_key field doesn't exist" do
              expect {
                subject.assign_foreign_key :foo_id, BSON::ObjectId.new
              }.to raise_error(NoMethodError)
            end
          end
        end
      end
    end
  end
end
