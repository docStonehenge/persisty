module Persisty
  module Persistence
    describe UnitOfWork do
      include_context 'StubEntity'

      describe '.new_current uow' do
        context 'when there is a current UnitOfWork running' do
          before do
            described_class.current = subject
            @registry       = described_class.current.clean_entities
            @dirty_tracking = described_class.current.dirty_tracking
          end

          it 'registers a new UnitOfWork instance on running thread using existing registry and dirty tracking' do
            described_class.new_current

            expect(
              Thread.current.thread_variable_get(:current_uow)
            ).to be_an_instance_of(described_class)

            expect(described_class.current.clean_entities).to eql @registry
            expect(described_class.current.dirty_tracking).to eql @dirty_tracking
          end
        end

        context "when no UnitOfWork is running on current Thread" do
          before do
            described_class.current = nil

            expect(
              Thread.current.thread_variable_get(:current_uow)
            ).to be_nil
          end

          it 'registers a new UnitOfWork instance on running thread using a new registry and dirty tracking' do
            new_registry = double(:entity_registry)
            new_tracking = double(:dirty_tracking)

            expect(Entities::Registry).to receive(:new).once.and_return new_registry

            expect(
              Entities::DirtyTrackingRegistry
            ).to receive(:new).once.and_return new_tracking

            described_class.new_current

            expect(
              Thread.current.thread_variable_get(:current_uow)
            ).to be_an_instance_of(described_class)

            expect(described_class.current.clean_entities).to equal new_registry
            expect(described_class.current.dirty_tracking).to equal new_tracking
          end
        end
      end

      describe '.current= uow' do
        it 'registers a UnitOfWork instance as current on running thread' do
          described_class.current = subject

          expect(
            Thread.current.thread_variable_get(:current_uow)
          ).to equal subject
        end
      end

      describe '.current' do
        it 'returns current UnitOfWork instance on running thread' do
          described_class.current = subject
          expect(described_class.current).to equal subject
        end

        it "starts a new unit of work on thread when it doesn't have any" do
          described_class.current = nil

          expect(described_class.current).to be_an_instance_of(described_class)
        end
      end

      subject do
        described_class.new(Entities::Registry.new, Entities::DirtyTrackingRegistry.new)
      end

      it do
        is_expected.to have_attributes(
                         clean_entities: an_instance_of(Entities::Registry),
                         dirty_tracking: an_instance_of(Entities::DirtyTrackingRegistry),
                         new_entities: an_instance_of(Set),
                         changed_entities: an_instance_of(Set),
                         removed_entities: an_instance_of(Set)
                       )
      end

      let(:clean_entities) { subject.clean_entities }
      let(:dirty_tracking) { subject.dirty_tracking }
      let(:new_entities) { subject.new_entities }
      let(:changed_entities) { subject.changed_entities }
      let(:removed_entities) { subject.removed_entities }
      let(:entity) { ::StubEntity.new(id: BSON::ObjectId.new) }

      describe '#get entity_class, entity_id' do
        it 'returns the entity set on clean entities list' do
          clean_entities.add(entity)
          expect(subject.get entity.class, entity.id).to equal entity
        end

        it 'returns nil if no entity was found' do
          expect(subject.get entity.class, entity.id).to be_nil
        end
      end

      describe '#register_changes_on entity' do
        it 'calls changes registration on dirty tracking for entity' do
          expect(
            dirty_tracking
          ).to receive(:register_changes_on).once.with(entity)

          subject.register_changes_on entity
        end
      end

      describe '#changes_on entity' do
        it 'returns all changes for entity registered on dirty_tracking' do
          expect(
            dirty_tracking
          ).to receive(:changes_on).once.with(entity).and_return(first_name: [nil, 'John'])

          expect(subject.changes_on(entity)).to eql(first_name: [nil, 'John'])
        end
      end

      describe '#commit' do
        let(:entity_to_save) { ::StubEntity.new(id: BSON::ObjectId.new) }
        let(:entity_to_update) { ::StubEntity.new(id: BSON::ObjectId.new) }
        let(:entity_to_delete) { ::StubEntity.new(id: BSON::ObjectId.new) }
        let(:repository) { double(:repository) }

        before do
          subject.register_new(entity_to_save)
          subject.track_clean(entity_to_update)

          allow(
            dirty_tracking
          ).to receive(:changes_on).once.with(entity_to_update).and_return(first_name: [nil, 'John'])

          subject.register_changed(entity_to_update)
          subject.register_removed(entity_to_delete)
        end

        context 'when all operations occur correctly' do
          it "traverses all lists with to-persist entities and calls repository methods" do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(entity_to_save.class).and_return repository

            expect(repository).to receive(:insert).once.with(entity_to_save)

            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(entity_to_update.class).and_return repository

            expect(repository).to receive(:update).once.with(entity_to_update)
            expect(dirty_tracking).to receive(:refresh_changes_on).once.with(entity_to_update)

            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(entity_to_delete.class).and_return repository

            expect(repository).to receive(:delete).once.with(entity_to_delete)

            expect(Repositories::Registry).to receive(:new_repositories).once

            expect(subject.commit).to be true

            expect(subject.new_entities).not_to include entity_to_save
            expect(subject.dirty_tracking).to include entity_to_save
          end
        end

        context 'when any operation fails' do
          it "stops all subsequent processes, doesn't clear list, but creates new registry" do
            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(entity_to_save.class).and_return repository

            expect(repository).to receive(:insert).once.with(entity_to_save)

            expect(
              Repositories::Registry
            ).to receive(:[]).once.with(entity_to_update.class).and_return repository

            expect(repository).to receive(:update).once.with(
                                    entity_to_update
                                  ).and_raise(RuntimeError, 'Error')

            expect(dirty_tracking).not_to receive(:refresh_changes_on).with(any_args)

            expect(
              Repositories::Registry
            ).not_to receive(:[]).with(entity_to_delete.class)

            expect(Repositories::Registry).to receive(:new_repositories).once

            expect {
              subject.commit
            }.to raise_error(RuntimeError)

            expect(subject.new_entities).not_to include entity_to_save
            expect(subject.dirty_tracking).to include entity_to_save
          end
        end
      end

      describe '#detach entity' do
        let(:entity) { ::StubEntity.new(id: BSON::ObjectId.new) }

        context 'when present only on clean_entities' do
          it 'deletes entity from clean_entities only' do
            subject.register_clean(entity)
            expect(subject.clean_entities).to include entity

            subject.detach entity

            expect(subject.clean_entities).not_to include entity
          end
        end

        context 'when present only on clean_entities and dirty_tracking' do
          it 'deletes entity from clean_entities and dirty_tracking only' do
            subject.track_clean(entity)
            expect(subject.clean_entities).to include entity
            expect(subject.dirty_tracking).to include entity

            subject.detach entity

            expect(subject.clean_entities).not_to include entity
            expect(subject.dirty_tracking).not_to include entity
          end
        end

        context 'when present on clean_entities, dirty_tracking changed_entities' do
          it 'deletes entity from clean_entities, dirty_tracking and changed_entities' do
            subject.track_clean(entity)

            allow(
              dirty_tracking
            ).to receive(:changes_on).with(entity).and_return(first_name: [nil, 'John'])

            subject.register_changed(entity)

            expect(subject.clean_entities).to include entity
            expect(subject.changed_entities).to include entity

            subject.detach entity

            expect(subject.clean_entities).not_to include entity
            expect(subject.changed_entities).not_to include entity
          end
        end

        context 'when present on clean_entities and new_entities' do
          it 'deletes entity from clean_entities and new_entities' do
            subject.register_new(entity)
            expect(subject.clean_entities).to include entity
            expect(subject.new_entities).to include entity

            subject.detach entity

            expect(subject.clean_entities).not_to include entity
            expect(subject.new_entities).not_to include entity
          end
        end

        context 'when present on removed_entities' do
          it 'deletes entity from removed_entities' do
            subject.register_removed(entity)
            expect(subject.removed_entities).to include entity

            subject.detach entity

            expect(subject.removed_entities).not_to include entity
          end
        end
      end

      describe '#clear' do
        it 'deletes all entities from all managed lists' do
          new_entity = ::StubEntity.new(id: BSON::ObjectId.new)
          changed_entity = ::StubEntity.new(id: BSON::ObjectId.new)
          removed_entity = ::StubEntity.new(id: BSON::ObjectId.new)

          subject.register_new(new_entity)
          subject.register_clean(changed_entity)
          subject.register_changed(changed_entity)
          subject.register_removed(removed_entity)

          subject.clear

          expect(subject.clean_entities).not_to include new_entity
          expect(subject.clean_entities).not_to include changed_entity
          expect(subject.new_entities).to be_empty
          expect(subject.changed_entities).to be_empty
          expect(subject.removed_entities).to be_empty
        end
      end

      describe '#managed? entity' do
        it 'is true when entity is present on clean entities' do
          subject.register_clean entity
          expect(subject.managed?(entity)).to be true
        end

        it 'is true when entity is present on clean entities and dirty tracking' do
          subject.track_clean entity
          expect(subject.managed?(entity)).to be true
        end

        it 'is true when entity is present on new entities' do
          subject.register_new entity
          expect(subject.managed?(entity)).to be true
        end

        it 'is true when entity is present on changed entities' do
          subject.track_clean entity
          subject.register_changed entity
          expect(subject.managed?(entity)).to be true
        end

        it 'is false when entity is present on removed entities' do
          subject.register_removed entity
          expect(subject.managed?(entity)).to be false
        end

        it 'is false when no registration lists to manage entity includes it' do
          expect(subject.managed?(entity)).to be false
        end
      end

      describe '#detached? entity' do
        it "is true when entity isn't present on any of the registration lists" do
          expect(subject.detached?(entity)).to be true
        end

        context 'when entity is present on list' do
          it 'is false when entity is present on clean entities' do
            subject.register_clean entity
            expect(subject.detached?(entity)).to be false
          end

          it 'is false when entity is present on clean entities and dirty tracking' do
            subject.track_clean entity
            expect(subject.detached?(entity)).to be false
          end

          it 'is false when entity is present on new entities' do
            subject.register_new entity
            expect(subject.detached?(entity)).to be false
          end

          it 'is false when entity is present on changed entities' do
            subject.track_clean entity
            subject.register_changed entity
            expect(subject.detached?(entity)).to be false
          end

          it 'is false when entity is present on removed entities' do
            subject.register_removed entity
            expect(subject.detached?(entity)).to be false
          end
        end
      end

      describe '#track_clean entity' do
        let(:entity) { ::StubEntity.new(id: BSON::ObjectId.new) }

        context "when clean_entities and dirty_tracking don't contain entity yet" do
          it 'adds entity to both maps' do
            subject.track_clean(entity)

            expect(clean_entities.get(entity.class.name, entity.id)).to equal entity
            expect(dirty_tracking).to include entity
          end
        end

        context "when entity doesn't contain ID field set" do
          let(:not_persisted_entity) { double(:entity, id: nil) }

          it "doesn't add to clean_entities nor dirty_tracking map" do
            subject.track_clean(not_persisted_entity)
            expect(clean_entities).not_to include not_persisted_entity
            expect(dirty_tracking).not_to include not_persisted_entity
          end
        end

        context 'when entity is present on new_entities' do
          it "doesn't add to dirty_tracking map" do
            subject.register_new(entity)

            subject.track_clean(entity)

            expect(dirty_tracking).not_to include entity
          end
        end

        context 'when entity is present on removed_entities' do
          it "doesn't add to dirty_tracking map" do
            subject.register_removed(entity)

            subject.track_clean(entity)

            expect(dirty_tracking).not_to include entity
          end
        end
      end

      describe '#register_clean entity' do
        let(:entity) { ::StubEntity.new(id: BSON::ObjectId.new) }

        context "when clean_entities list doesn't contain entity yet" do
          it 'adds entity to clean_entities map' do
            subject.register_clean(entity)
            expect(clean_entities.get(entity.class.name, entity.id)).to equal entity
          end
        end

        context 'when clean_entities already contains entity' do
          it "doesn't add same database registry twice" do
            another_entity = ::StubEntity.new(id: entity.id)

            subject.register_clean(entity)
            subject.register_clean(another_entity)

            expect(
              clean_entities.get(::StubEntity, another_entity.id)
            ).not_to equal another_entity
          end
        end

        context "when entity doesn't contain ID field set" do
          let(:not_persisted_entity) { double(:entity, id: nil) }

          it "doesn't add to clean_entities list" do
            subject.register_clean(not_persisted_entity)
            expect(clean_entities).not_to include not_persisted_entity
          end
        end
      end

      describe '#register_new entity' do
        let(:entity) { ::StubEntity.new(id: BSON::ObjectId.new) }

        context "when new_entities list doesn't contain entity yet" do
          it 'adds entity to new_entities list and to clean entities' do
            subject.register_new(entity)
            expect(new_entities.first).to equal entity
            expect(clean_entities.get(entity.class, entity.id)).to eql entity
          end
        end

        context 'when new_entities already contains entity' do
          it "doesn't add same object twice" do
            subject.register_new(entity)
            subject.register_new(entity)

            expect(new_entities).to contain_exactly(entity)
          end
        end

        context "when entity doesn't contain ID field set" do
          let(:not_persisted_entity) { double(:entity, id: nil) }

          it "doesn't add to new_entities list" do
            subject.register_new(not_persisted_entity)
            expect(new_entities).not_to include not_persisted_entity
          end
        end

        context 'when entity is present in another list' do
          it "doesn't add to new_entities list when present on changed_entities" do
            subject.track_clean(entity)
            subject.register_changed(entity)
            subject.register_new(entity)

            expect(new_entities).not_to include entity
          end

          it "doesn't add to new_entities list when present on removed_entities" do
            subject.register_removed(entity)
            subject.register_new(entity)

            expect(new_entities).not_to include entity
          end

          it "doesn't add to new_entities list when present on dirty_tracking" do
            entity = ::StubEntity.new(id: BSON::ObjectId.new)
            subject.track_clean(entity)
            subject.register_new(entity)

            expect(new_entities).not_to include entity
          end
        end
      end

      describe '#register_changed entity' do
        let(:entity) { ::StubEntity.new(id: BSON::ObjectId.new) }

        context "when changed_entities list doesn't contain entity yet" do
          before do
            subject.track_clean(entity)
          end

          context 'when entity has changes' do
            before do
              allow(
                dirty_tracking
              ).to receive(:changes_on).with(entity).and_return(first_name: [nil, 'John'])
            end

            it 'adds entity to changed_entities list after registering changes' do
              expect(subject).to receive(:register_changes_on).once.with(entity)

              subject.register_changed(entity)
              expect(changed_entities.first).to equal entity
            end
          end

          context "when entity doesn't have changes" do
            before do
              allow(
                dirty_tracking
              ).to receive(:changes_on).with(entity).and_return({})
            end

            it "doesn't add to changed_entities" do
              expect(subject).to receive(:register_changes_on).once.with(entity)

              subject.register_changed(entity)
              expect(changed_entities).not_to include entity
            end
          end
        end

        context 'when changed_entities already contains entity' do
          it "doesn't add same object twice" do
            subject.track_clean(entity)

            expect(subject).to receive(:register_changes_on).twice.with(entity)

            allow(
              dirty_tracking
            ).to receive(:changes_on).with(entity).and_return(first_name: [nil, 'John'])

            subject.register_changed(entity)
            subject.register_changed(entity)

            expect(changed_entities).to contain_exactly(entity)
          end
        end

        context "when entity doesn't contain ID field set" do
          let(:not_persisted_entity) { double(:entity, id: nil) }

          it "doesn't add to changed_entities list" do
            expect(subject).not_to receive(:register_changes_on).with(any_args)

            subject.register_changed(not_persisted_entity)

            expect(changed_entities).not_to include not_persisted_entity
          end
        end

        context 'when entity is present in another list' do
          it "doesn't add to changed_entities list when present on new_entities" do
            subject.register_new(entity)

            expect(subject).not_to receive(:register_changes_on).with(any_args)

            subject.register_changed(entity)

            expect(changed_entities).not_to include entity
          end

          it "doesn't add to changed_entities list when present on removed_entities" do
            subject.register_removed(entity)

            expect(subject).not_to receive(:register_changes_on).with(any_args)

            subject.register_changed(entity)

            expect(changed_entities).not_to include entity
          end

          it "doesn't add to changed_entities when not present on dirty_tracking" do
            subject.register_clean(entity)

            expect(subject).not_to receive(:register_changes_on).with(any_args)

            subject.register_changed(entity)

            expect(changed_entities).not_to include entity
          end
        end
      end

      describe '#register_removed entity' do
        let(:entity) { ::StubEntity.new(id: BSON::ObjectId.new) }

        context "when removed_entities list doesn't contain entity yet" do
          it 'adds entity to removed_entities list' do
            subject.register_removed(entity)
            expect(removed_entities.first).to equal entity
          end

          it 'removes entity from clean_entities first' do
            subject.register_clean(entity)
            subject.register_removed(entity)

            expect(removed_entities.first).to equal entity
            expect(clean_entities.get(entity.class, entity.id)).to be_nil
          end
        end

        context 'when removed_entities already contains entity' do
          it "doesn't add same object twice" do
            subject.register_removed(entity)
            subject.register_removed(entity)

            expect(removed_entities).to contain_exactly(entity)
          end
        end

        context "when entity doesn't contain ID field set" do
          let(:not_persisted_entity) { double(:entity, id: nil) }

          it "doesn't add to removed_entities list" do
            subject.register_removed(not_persisted_entity)
            expect(removed_entities).not_to include not_persisted_entity
          end
        end

        context 'when entity is present in another list' do
          it "doesn't add to removed_entities and remove from new_entities" do
            subject.register_new(entity)
            expect(new_entities).to include entity

            subject.register_removed(entity)

            expect(removed_entities).not_to include entity
            expect(new_entities).not_to include entity
          end

          it "removes from dirty tracking and changed_entities before setting on removed_entities" do
            subject.track_clean(entity)

            allow(
              dirty_tracking
            ).to receive(:changes_on).with(entity).and_return(first_name: [nil, 'John'])

            subject.register_changed(entity)
            expect(changed_entities).to include entity
            expect(dirty_tracking).to include entity

            subject.register_removed(entity)

            expect(changed_entities).not_to include entity
            expect(dirty_tracking).not_to include entity
            expect(removed_entities).to include entity
          end

          it "removes from clean_entities before setting on removed_entities" do
            entity = ::StubEntity.new(id: BSON::ObjectId.new)

            subject.register_clean(entity)
            subject.register_removed(entity)

            expect(clean_entities.get(::StubEntity, entity.id)).to be_nil
            expect(removed_entities).to include entity
          end
        end
      end
    end
  end
end
