module Persisty
  module Persistence
    module DocumentDefinitions
      describe Base do
        let(:uow) { double(:uow) }
        let!(:id) { BSON::ObjectId.new }

        describe 'ClassMethods' do
          let(:described_class) { Class.new { include Base } }

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

          context 'attributes' do
            let(:field) { double(:field) }

            describe '.define_field name, type:' do
              context 'when field is ID' do
                context 'when entity is handled by current UnitOfWork' do
                  before do
                    @subject = described_class.new(id: BSON::ObjectId.new)
                    Persistence::UnitOfWork.new_current
                    Persistence::UnitOfWork.current.register_clean @subject
                  end

                  it 'defines getter and setter for field, and setter will raise ArgumentError' do
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

                  it 'defines getter and setter for field, allows setting id correctly' do
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

                  it 'defines getter and setter for field, allows setting id correctly' do
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

                  it 'defines getter, setter, converting field and registering object into UnitOfWork' do
                    expect {
                      @subject.name = 'New name'

                      expect(
                        Persistence::UnitOfWork.current.managed?(@subject)
                      ).to be true
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

                  it 'defines getter and setter for field; setter does not register on UnitOfWork' do
                    expect {
                      @subject.name = 'New name'

                      expect(
                        Persistence::UnitOfWork.current.managed?(@subject)
                      ).to be false
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

                  it 'defines getter, setter, converting field only' do
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
          class TestEntity
            include Base

            define_field :first_name, type: String
            define_field :dob,        type: Date
          end

          let(:described_class) { TestEntity }

          context 'can be initialized with any atributes' do
            it 'can be initialized without any attributes' do
              subject = described_class.new

              expect(subject.id).to be_nil
              expect(subject.first_name).to be_nil
              expect(subject.dob).to be_nil
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

            context 'when ID field is included' do
              it 'returns fields names and values mapped into a Hash' do
                expect(
                  subject.to_hash
                ).to eql(id: id, first_name: 'John', dob: Date.parse('1990/01/01'))
              end
            end

            context 'when ID field is not included' do
              it 'returns fields names and values mapped into a Hash, without ID' do
                expect(
                  subject.to_hash(include_id_field: false)
                ).to eql(first_name: 'John', dob: Date.parse('1990/01/01'))
              end
            end
          end

          describe '#to_mongo_document' do
            class EntityWithAllValues
              include Base

              define_field :field1, type: String
              define_field :field2, type: Integer
              define_field :field3, type: Float
              define_field :field4, type: BigDecimal
              define_field :field5, type: Boolean
              define_field :field6, type: Array
              define_field :field7, type: Hash
              define_field :field8, type: BSON::ObjectId
              define_field :field9, type: Date
              define_field :field10, type: DateTime
              define_field :field11, type: Time
            end

            subject do
              EntityWithAllValues.new(
                id: id,
                field1: "Foo",
                field2: 123,
                field3: 123.0,
                field4: BigDecimal.new("123.0"),
                field5: true,
                field6: [123, BigDecimal.new("200")],
                field7: { foo: Date.parse("01/01/1990"), 'bazz' => BigDecimal.new(400) },
                field8: id,
                field9: Date.parse('01/01/1990'),
                field10: DateTime.new(2017, 11, 21),
                field11: Time.new(2017, 11, 21)
              )
            end

            it "maps fields names and values, with mongo permitted values and '_id' field" do
              expect(
                subject.to_mongo_document
              ).to eql(
                     _id: id,
                     field1: "Foo",
                     field2: 123,
                     field3: 123.0,
                     field4: 123.0,
                     field5: true,
                     field6: [123, 200.0],
                     field7: { foo: Date.parse("01/01/1990"), 'bazz' => 400.0 },
                     field8: id,
                     field9: Date.parse('01/01/1990'),
                     field10: DateTime.new(2017, 11, 21),
                     field11: Time.new(2017, 11, 21)
                   )
            end

            it "maps fields names and values, with mongo permitted values, without '_id' field" do
              expect(
                subject.to_mongo_document(include_id_field: false)
              ).to eql(
                     field1: "Foo",
                     field2: 123,
                     field3: 123.0,
                     field4: 123.0,
                     field5: true,
                     field6: [123, 200.0],
                     field7: { foo: Date.parse("01/01/1990"), 'bazz' => 400.0 },
                     field8: id,
                     field9: Date.parse('01/01/1990'),
                     field10: DateTime.new(2017, 11, 21),
                     field11: Time.new(2017, 11, 21)
                   )
            end
          end
        end
      end
    end
  end
end
