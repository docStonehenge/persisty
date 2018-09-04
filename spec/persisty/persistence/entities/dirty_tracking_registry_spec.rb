module Persisty
  module Persistence
    module Entities
      describe DirtyTrackingRegistry do
        ::DirtyTrackedEntity = Class.new.include(
          Persistence::DocumentDefinitions::Base
        )

        ::DirtyTrackedEntity.define_field(:first_name, type: String)
        ::DirtyTrackedEntity.define_field(:age, type: Integer)
        ::DirtyTrackedEntity.define_field(:wage, type: BigDecimal)

        context 'as a subclass of Registry' do
          it { is_expected.to have_attributes(entities: {}) }
          it { is_expected.to respond_to :add }
          it { is_expected.to respond_to :get }
          it { is_expected.to respond_to :include? }
          it { is_expected.to respond_to :delete }
          it { is_expected.to respond_to :clear }
        end

        let(:id) { BSON::ObjectId.new }

        describe '#add entity' do
          it 'adds entities splat attributes to entities hash, with key as class name and database ID' do
            entity = ::DirtyTrackedEntity.new(id: id)

            another_entity = ::DirtyTrackedEntity.new(
              id: BSON::ObjectId.new, first_name: 'Foo', age: 30, wage: 500.0
            )

            subject.add(entity)
            subject.add(another_entity)

            expect(subject.entities.size).to eql 2
            expect(subject.entities).to have_key("dirtytrackedentity>>#{id}")
            expect(subject.entities).to have_key("dirtytrackedentity>>#{another_entity.id}")

            expect(
              subject.entities.dig("dirtytrackedentity>>#{id}")
            ).to eql(first_name: [nil], age: [nil], wage: [nil])

            expect(
              subject.entities.dig("dirtytrackedentity>>#{another_entity.id}")
            ).to eql(first_name: ['Foo'], age: [30], wage: [BigDecimal.new('500')])
          end

          it "doesn't add another object with same ID and class when already present" do
            entity = ::DirtyTrackedEntity.new(id: id)

            subject.add(entity)

            another_entity = ::DirtyTrackedEntity.new(
              id: id, first_name: 'Foo', age: 30, wage: 500.0
            )

            subject.add(another_entity)

            expect(subject.entities.size).to eql 1
            expect(subject.entities).to have_key("dirtytrackedentity>>#{id}")

            expect(
              subject.entities.dig("dirtytrackedentity>>#{id}")
            ).to eql(first_name: [nil], age: [nil], wage: [nil])
          end

          it 'adds another entity object with same ID but different class' do
            entity = ::DirtyTrackedEntity.new(id: id)

            subject.add(entity)

            ::AnotherEntity = Class.new.include(
              Persistence::DocumentDefinitions::Base
            )

            ::AnotherEntity.define_field(:name, type: String)
            other_entity = AnotherEntity.new(id: id)

            subject.add(other_entity)

            expect(subject.entities.size).to eql 2
            expect(subject.entities).to have_key("dirtytrackedentity>>#{id}")
            expect(subject.entities).to have_key("anotherentity>>#{id}")

            expect(
              subject.entities.dig("dirtytrackedentity>>#{id}")
            ).to eql(first_name: [nil], age: [nil], wage: [nil])

            expect(
              subject.entities.dig("anotherentity>>#{id}")
            ).to eql(name: [nil])
          end

          it 'adds two objects of same entity and different IDs' do
            another_id = BSON::ObjectId.new
            entity = ::DirtyTrackedEntity.new(id: id, first_name: 'Foo')

            subject.add(entity)

            other_entity = ::DirtyTrackedEntity.new(id: another_id, first_name: 'Bar', age: 50)

            subject.add(other_entity)

            expect(subject.entities.size).to eql 2
            expect(subject.entities).to have_key("dirtytrackedentity>>#{id}")
            expect(subject.entities).to have_key("dirtytrackedentity>>#{another_id}")

            expect(
              subject.entities.dig("dirtytrackedentity>>#{id}")
            ).to eql(first_name: ['Foo'], age: [nil], wage: [nil])

            expect(
              subject.entities.dig("dirtytrackedentity>>#{another_id}")
            ).to eql(first_name: ['Bar'], age: [50], wage: [nil])
          end
        end

        describe '#register_changes_on entity' do
          context 'when entity has values different from previously mapped' do
            it 'adds change for each attribute changed on entity' do
              entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

              subject.add(entity)

              entity.first_name = 'Fooza'
              entity.age  = 30
              entity.wage = 1_000_000

              subject.register_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: [nil, 'Fooza'], age: [nil, 30], wage: [BigDecimal.new('500'), BigDecimal.new('1_000_000')])
            end
          end

          context "when entity has values that didn't change from previous mapped" do
            it 'adds change only for changed attributes' do
              entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

              subject.add(entity)

              entity.first_name = 'Fooza'

              subject.register_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: [nil, 'Fooza'], age: [nil], wage: [BigDecimal.new('500')])
            end
          end

          context 'when changes go back to previously mapped value' do
            it "doesn't add 'equal value' change" do
              entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

              subject.add(entity)

              entity.first_name = 'Fooza'
              entity.age  = 30
              entity.wage = 1_000_000

              subject.register_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: [nil, 'Fooza'], age: [nil, 30], wage: [BigDecimal.new('500'), BigDecimal.new('1_000_000')])

              entity.first_name = nil
              entity.age  = nil
              entity.wage = 500

              subject.register_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: [nil], age: [nil], wage: [BigDecimal.new('500')])
            end
          end

          context 'when changes are made in sequence before remapping' do
            it 'adds only last changes on entity' do
              entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

              subject.add(entity)

              entity.first_name = 'Fooza'
              entity.age  = 30
              entity.wage = 1_000_000

              subject.register_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: [nil, 'Fooza'], age: [nil, 30], wage: [BigDecimal.new('500'), BigDecimal.new('1_000_000')])

              entity.first_name = 'Foobar'
              entity.age  = 32
              entity.wage = 1_500

              subject.register_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: [nil, 'Foobar'], age: [nil, 32], wage: [BigDecimal.new('500'), BigDecimal.new('1_500')])
            end
          end

          it "halts execution when tracking isn't found on map" do
            entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

            track = subject.entities.dig("dirtytrackedentity>>#{id}")

            entity.first_name = 'Fooza'
            expect(subject.register_changes_on(entity)).to be_nil

            expect(subject.entities.dig("dirtytrackedentity>>#{id}")).to eql track
          end
        end

        describe '#refresh_changes_on entity' do
          context 'when entity has changes on attributes' do
            it 'removes previous values on each attribute array' do
              entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

              subject.add(entity)

              entity.first_name = 'Fooza'
              entity.age  = 30
              entity.wage = 1_000_000

              subject.register_changes_on(entity)
              subject.refresh_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: ['Fooza'], age: [30], wage: [BigDecimal.new('1_000_000')])
            end
          end

          context 'when entity has attributes without changes' do
            it 'removes previous values only from attributes with changes' do
              entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

              subject.add(entity)

              entity.first_name = 'Fooza'

              subject.register_changes_on(entity)
              subject.refresh_changes_on(entity)

              expect(
                subject.entities.dig("dirtytrackedentity>>#{id}")
              ).to eql(first_name: ['Fooza'], age: [nil], wage: [BigDecimal.new('500')])
            end
          end

          it "halts execution when tracking isn't found on map" do
            entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

            track = subject.entities.dig("dirtytrackedentity>>#{id}")
            expect(subject.entities.dig("dirtytrackedentity>>#{id}")).to be_nil

            entity.first_name = 'Fooza'
            subject.refresh_changes_on(entity)

            expect(subject.entities.dig("dirtytrackedentity>>#{id}")).to eql track
          end
        end

        describe '#changes_on entity' do
          it 'returns a hash with all attributes that changed, including previous and new value' do
            entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

            subject.add(entity)

            entity.first_name = 'Fooza'
            entity.age  = 30
            entity.wage = 1_000_000

            subject.register_changes_on(entity)

            expect(
              subject.changes_on(entity)
            ).to eql(first_name: [nil, 'Fooza'], age: [nil, 30], wage: [BigDecimal.new('500'), BigDecimal.new('1_000_000')])
          end

          it 'returns only keys on hash for attributes that had changes' do
            entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

            subject.add(entity)

            entity.first_name = 'Fooza'
            entity.wage = 1_000_000

            subject.register_changes_on(entity)

            expect(
              subject.changes_on(entity)
            ).to eql(first_name: [nil, 'Fooza'], wage: [BigDecimal.new('500'), BigDecimal.new('1_000_000')])
          end

          it "halts execution when entity isn't yet tracked" do
            entity = ::DirtyTrackedEntity.new(id: id, wage: 500.0)

            entity.first_name = 'Fooza'
            entity.wage = 1_000_000

            expect(subject.changes_on(entity)).to be_nil
          end
        end
      end
    end
  end
end
