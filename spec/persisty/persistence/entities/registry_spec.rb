module Persisty
  module Persistence
    module Entities
      describe Registry do
        include_context 'StubEntity'

        let(:id) { BSON::ObjectId.new }

        it { is_expected.to have_attributes(entities: {}) }

        describe '#add entity' do
          it 'adds entity object to entities hash, with key as class name and database ID' do
            entity = ::StubEntity.new(id: id)

            subject.add(entity)

            expect(subject.entities.size).to eql 1
            expect(subject.entities).to have_key("stubentity>>#{id}")

            expect(
              subject.entities.dig("stubentity>>#{id}")
            ).to equal entity
          end

          it "doesn't add another object with same ID and class when already present" do
            entity = ::StubEntity.new(id: id)

            subject.add(entity)

            another_entity = ::StubEntity.new(id: id)

            subject.add(another_entity)

            expect(subject.entities.size).to eql 1
            expect(subject.entities).to have_key("stubentity>>#{id}")

            expect(
              subject.entities.dig("stubentity>>#{id}")
            ).not_to equal another_entity

            expect(
              subject.entities.dig("stubentity>>#{id}")
            ).to equal entity
          end

          it 'adds another entity object with same ID but different class' do
            entity = ::StubEntity.new(id: id)

            subject.add(entity)

            ::AnotherEntity = Struct.new(:id)

            other_entity = AnotherEntity.new(id)

            subject.add(other_entity)

            expect(subject.entities.size).to eql 2
            expect(subject.entities).to have_key("stubentity>>#{id}")
            expect(subject.entities).to have_key("anotherentity>>#{id}")

            expect(
              subject.entities.dig("stubentity>>#{id}")
            ).to equal entity

            expect(
              subject.entities.dig("anotherentity>>#{id}")
            ).to equal other_entity
          end

          it 'adds two objects of same entity and different IDs' do
            another_id = BSON::ObjectId.new
            entity = ::StubEntity.new(id: id)

            subject.add(entity)

            other_entity = ::StubEntity.new(id: another_id)

            subject.add(other_entity)

            expect(subject.entities.size).to eql 2
            expect(subject.entities).to have_key("stubentity>>#{id}")
            expect(subject.entities).to have_key("stubentity>>#{another_id}")

            expect(
              subject.entities.dig("stubentity>>#{id}")
            ).to equal entity

            expect(
              subject.entities.dig("stubentity>>#{another_id}")
            ).to equal other_entity
          end
        end

        describe '#get class_name, id' do
          it 'returns class_name entity object found by ID' do
            entity = ::StubEntity.new(id: BSON::ObjectId.new)

            subject.add(entity)

            expect(
              subject.get(entity.class, entity.id)
            ).to equal entity
          end

          it 'returns class_name entity object found by ID, with name as string' do
            entity = ::StubEntity.new(id: id)

            subject.add(entity)

            expect(
              subject.get('StubEntity', entity.id)
            ).to equal entity
          end

          it 'returns nil if no object is found' do
            expect(
              subject.get('', id)
            ).to be_nil
          end
        end

        describe '#include? entity' do
          it 'is true if entities map has entity by class name and ID' do
            entity = ::StubEntity.new(id: id)

            subject.add(entity)

            expect(subject.include?(entity)).to be true
          end

          it 'is false if entity is not found' do
            expect(subject.include?(::StubEntity.new(id: id))).to be false
          end
        end

        describe '#delete entity' do
          it 'removes entity from entities map and returns it' do
            entity = ::StubEntity.new(id: id)

            subject.add(entity)

            expect(subject.delete(entity)).to eql entity
          end

          it 'returns nil if no entity was removed' do
            expect(
              subject.delete(::StubEntity.new(id: id))
            ).to be_nil
          end
        end

        describe '#clear' do
          it 'empties entities hash' do
            entities = [
              ::StubEntity.new(id: id),
              ::StubEntity.new(id: 123),
              ::StubEntity.new(id: 244)
            ]

            entities.each { |entity| subject.add entity }

            expect(subject.entities).not_to be_empty

            subject.clear

            expect(subject.entities).to be_empty
          end
        end
      end
    end
  end
end
