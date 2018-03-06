shared_context 'StubRepository' do
  class ::StubRepository
    include Persisty::Repositories::Base

    private

    def entity_klass
      ::StubEntity
    end

    def collection_name
      :stub_entities
    end
  end

  let(:repo) { ::StubRepository.new }
end
