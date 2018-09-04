require 'persisty/string_modifiers/base'

module Persisty
  module StringModifiers
    # A helper object to provide correct plurals to words.
    # It's initialized with a map of Regexp=>String key-value pairs, which is just
    # an approximation to start working with pluralizations on repository names.
    class Pluralizer < Base
      # Pluralizes <tt>word</tt> according to locale set (it uses 'default' locale as default.)
      # Tries to pluralize word following English rules of pluralization. Any word
      # that doesn't match any specific rules are just modified with an appended 's'.
      # If word is already pluralized, it's not modified.
      alias pluralize modify

      private

      def define_modification_rules
        {
          default: {
            /$/i => 's', /s$/i => 's', /(?!<[^aeiou]{1}>)y$/i => 'ies',
            /(epo|stoma)ch$/i => '\\0s', /(ss|x|ch|sh|z)$/i => '\1es',
            /(bu)s$/i => '\\0es', /\w*[aeiou]ch$/i => '\\0s',
            /(?!<[aeiou]{1}>)fe$|(?<![aeiou])f$/i => '\1ves',
            /(?<![^aeiou]{1})f$/i => '\\0s', /\w*o$/i => '\\0s',
            /(tomat|potat|her)o$/i => '\\0es', /(p)erson$/i => '\1eople',
            /(p)eople/i => '\1eople', /(child)$/i => '\1ren',
            /(children)$/i => '\1', /(zombie)$/i => '\1s',
            /(zombies)$/i => '\1'
          }
        }
      end
    end
  end
end
