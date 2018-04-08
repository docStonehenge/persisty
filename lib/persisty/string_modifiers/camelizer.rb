require 'persisty/string_modifiers/base'

module Persisty
  module StringModifiers
    class Camelizer < Base
      alias camelize modify

      private

      def define_modification_rules
        { default: { /\b[a-z](?<!_)|(?<=_)[a-z]/ => -> (c) { c.capitalize } } }
      end

      def change_word_based_on(rules, rule_key, new_word)
        new_word.gsub!(rule_key, &rules.fetch(rule_key)).gsub!(/[_]/, '')
      end
    end
  end
end
