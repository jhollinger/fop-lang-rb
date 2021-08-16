module Fop
  class Tokenizer
    Char = Struct.new(:char)
    Op = Struct.new(:tokens)
    Regex = Struct.new(:src)
    Error = Class.new(StandardError)

    OP_OPEN = "{".freeze
    OP_CLOSE = "}".freeze
    ESCAPE = "\\".freeze
    WILDCARD = "*".freeze
    REGEX_MARKER = "/".freeze

    def initialize(src)
      @src = src
      @end = src.size - 1
    end

    def tokenize!
      tokens = []
      escape = false
      i = 0
      until i > @end do
        char = @src[i]
        if escape
          tokens << Char.new(char)
          escape = false
          i += 1
          next
        end

        case char
        when ESCAPE
          escape = true
          i += 1
        when OP_OPEN
          i, op = operation! i + 1
          tokens << op
        when OP_CLOSE
          raise "Unexpected #{OP_CLOSE}"
        when WILDCARD
          tokens << :wildcard
          i += 1
        else
          tokens << Char.new(char)
          i += 1
        end
      end

      raise Error, "Trailing escape" if escape
      tokens
    end

    private

    def operation!(i)
      escape = false
      found_close = false
      tokens = []

      until found_close or i > @end do
        char = @src[i]
        if escape
          tokens << Char.new(char)
          escape = false
          i += 1
          next
        end

        case char
        when ESCAPE
          escape = true
          i += 1
        when OP_OPEN
          raise "Unexpected #{OP_OPEN}"
        when OP_CLOSE
          found_close = true
          i += 1
        when REGEX_MARKER
          i, reg = regex! i + 1
          tokens << reg
        else
          tokens << Char.new(char)
          i += 1
        end
      end

      raise Error, "Unclosed operation" if !found_close
      raise Error, "Trailing escape" if escape
      return i, Op.new(tokens)
    end

    def regex!(i)
      escape = false
      found_close = false
      src = ""

      until found_close or i > @end
        char = @src[i]
        i += 1

        if escape
          src << char
          escape = false
          next
        end

        case char
        when ESCAPE
          escape = true
        when REGEX_MARKER
          found_close = true
        else
          src << char
        end
      end

      raise Error, "Unclosed regex" if !found_close
      raise Error, "Trailing escape" if escape
      return i, Regex.new(src)
    end
  end
end
