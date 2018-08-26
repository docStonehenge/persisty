shared_context 'parent node' do
  class ::Parent
    include Persisty::Persistence::DocumentDefinitions::Base

    def self.repository
      ::ParentRepository
    end
  end

  class ::ParentRepository
    include Persisty::Repositories::Base

    private

    def entity_klass
      ::Parent
    end

    def collection_name
      :parents
    end
  end

  let(:parent) { ::Parent.new }
end
