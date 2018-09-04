describe 'Persistence::UnitOfWork integration tests', db_integration: true do
  include_context 'StubEntity'

  let(:entity_registry) { Persisty::Persistence::Entities::Registry.new }
  let(:dirty_tracking) { Persisty::Persistence::Entities::DirtyTrackingRegistry.new }

  subject { Persisty::Persistence::UnitOfWork.new(entity_registry, dirty_tracking) }

  before do
    Thread.current.thread_variable_set(:current_uow, nil)
  end

  it 'sets unit of work object into current Thread only' do
    Persisty::Persistence::UnitOfWork.current = subject
    expect(Persisty::Persistence::UnitOfWork.current).to equal subject

    expect {
      Thread.new { Persisty::Persistence::UnitOfWork.current }.join
    }.to raise_error(Persisty::Persistence::UnitOfWorkNotStartedError)
  end

  it 'sets a new unit of work object into current Thread' do
    Persisty::Persistence::UnitOfWork.new_current

    expect(
      Persisty::Persistence::UnitOfWork.current
    ).to be_an_instance_of Persisty::Persistence::UnitOfWork

    expect {
      Thread.new { Persisty::Persistence::UnitOfWork.current }.join
    }.to raise_error(Persisty::Persistence::UnitOfWorkNotStartedError)
  end

  it 'uses same entity registry from existing uow on new one registered' do
    Persisty::Persistence::UnitOfWork.current = subject
    new_uow = Persisty::Persistence::UnitOfWork.new_current

    expect(Persisty::Persistence::UnitOfWork.current).to equal new_uow
    expect(new_uow.clean_entities).to equal entity_registry
    expect(new_uow.dirty_tracking).to equal dirty_tracking
  end

  it 'uses new entity registry and dirty tracking on new UnitOfWork when no current_uow is set' do
    expect {
      Persisty::Persistence::UnitOfWork.current
    }.to raise_error(Persisty::Persistence::UnitOfWorkNotStartedError)

    new_registry = double(:entity_registry)
    new_track    = double(:dirty_tracking)

    expect(
      Persisty::Persistence::Entities::Registry
    ).to receive(:new).once.and_return new_registry

    expect(
      Persisty::Persistence::Entities::DirtyTrackingRegistry
    ).to receive(:new).once.and_return new_track

    new_uow = Persisty::Persistence::UnitOfWork.new_current

    expect(Persisty::Persistence::UnitOfWork.current).to equal new_uow
    expect(new_uow.clean_entities).to equal new_registry
    expect(new_uow.dirty_tracking).to equal new_track
  end

  context 'getting entity registered as clean' do
    let(:entity) { StubEntity.new(id: BSON::ObjectId.new) }

    it 'returns a clean entity set on unit of work' do
      Persisty::Persistence::UnitOfWork.new_current

      uow = Persisty::Persistence::UnitOfWork.current

      uow.register_clean(entity)

      expect(uow.get(entity.class, entity.id)).to equal entity
      expect(uow.get(entity.class, entity.id)).to equal entity
    end

    it 'returns nil if no entity is found' do
      Persisty::Persistence::UnitOfWork.new_current
      uow = Persisty::Persistence::UnitOfWork.current

      expect(uow.get(entity.class, entity.id)).to be_nil
    end
  end
end
