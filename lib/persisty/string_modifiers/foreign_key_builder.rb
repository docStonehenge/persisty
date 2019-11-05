module Persisty
  module StringModifiers
    class ForeignKeyBuilder
      def build_foreign_key_from(word)
        to_modify = word.to_s.strip.underscore.downcase
        return word if to_modify.empty?

        to_modify.end_with?('_id') ? to_modify : to_modify + '_id'
      end

      def name_from_foreign_key(foreign_key)
        foreign_key.to_s.strip.sub!(/_id$/, '') || foreign_key
      end
    end
  end
end
