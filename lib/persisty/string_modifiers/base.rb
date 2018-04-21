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

        if (key = rule_key_for(word, rules))
          change_word_based_on rules, key, word_to_modify
        end

        word_to_modify
      end

      private

      def rule_key_for(word, rules)
        rules.keys.select { |rule| rule.match(word) }.last
      end

      def change_word_based_on(rules, rule_key, new_word)
        new_word.sub!(rule_key, rules.fetch(rule_key))
      end
    end
  end
end
