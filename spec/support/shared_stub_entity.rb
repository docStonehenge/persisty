shared_context 'StubEntity' do
  class ::StubEntity
    include Persisty::Persistence::DocumentDefinitions::Base
  end

  let(:entity) { ::StubEntity.new }
end
