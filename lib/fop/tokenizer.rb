module Fop
  class Tokenizer
    Char = Struct.new(:char)
    Op = Struct.new(:match, :operator, :arg)
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
        i += 1

        if escape
          tokens << Char.new(char)
          escape = false
          next
        end

        case char
        when ESCAPE
          escape = true
        when OP_OPEN
          i, op = operation! i
          tokens << op
        when OP_CLOSE
          raise "Unexpected #{OP_CLOSE}"
        when WILDCARD
          tokens << :wildcard
        else
          tokens << Char.new(char)
        end
      end

      raise Error, "Trailing escape" if escape
      tokens
    end

    private

    def operation!(i)
      found_close = false
      op = Op.new(nil, nil, "")

      # Find matcher
      until found_close or op.match or i > @end do
        char = @src[i]
        i += 1
        case char
        when OP_CLOSE
          found_close = true
        when REGEX_MARKER
          i, reg = regex! i
          op.match = reg
        else
          op.match = Char.new(char)
        end
      end

      # Find operator
      until found_close or op.operator or i > @end do
        char = @src[i]
        i += 1
        case char
        when OP_CLOSE
          found_close = true
        else
          op.operator = Char.new(char)
        end
      end

      # Find operator arg
      escape = false
      until found_close or i > @end do
        char = @src[i]
        i += 1

        if escape
          op.arg << char
          escape = false
          next
        end

        case char
        when ESCAPE
          escape = true
        when OP_OPEN
          raise "Unexpected #{OP_OPEN}"
        when OP_CLOSE
          found_close = true
        else
          op.arg << char
        end
      end

      raise Error, "Unclosed operation" if !found_close
      raise Error, "Trailing escape" if escape
      return i, op
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
