module Fop
  module Tokenizer
    Char = Struct.new(:char)
    Error = Class.new(StandardError)

    def self.tokenize!(src)
      tokens = []
      escape = false
      src.each_char { |char|
        if escape
          tokens << Char.new(char)
          escape = false
          next
        end

        case char
        when "\\".freeze
          escape = true
        when "{".freeze
          tokens << :match_open
        when "}".freeze
          tokens << :match_close
        when "*".freeze
          tokens << :wildcard
        else
          tokens << Char.new(char)
        end
      }

      raise Error, "Trailing escape" if escape
      tokens
    end
  end
end
