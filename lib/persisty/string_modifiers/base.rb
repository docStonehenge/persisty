module Persisty
  module StringModifiers
    class Base
      def initialize
        @rules = define_modification_rules
      end

      def modify(word, locale: :default)
        rules          = @rules[locale.to_sym]
        word_to_modify = word.to_s.dup

        return word_to_modify if word.empty?

        if (key = rules.keys.find { |rule| rule.match(word) })
          word_to_modify.sub!(/#{Regexp.new(key.to_s)}/, rules.fetch(key))
        end

        word_to_modify
      end
    end
  end
end
