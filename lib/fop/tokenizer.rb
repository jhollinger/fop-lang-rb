require_relative 'tokens'

module Fop
  class Tokenizer
    Token = Struct.new(:pos, :type, :val)
    Error = Class.new(StandardError)

    EXP_OPEN = "{".freeze
    EXP_CLOSE = "}".freeze
    ESCAPE = "\\".freeze
    WILDCARD = "*".freeze
    REGEX_DELIM = "/".freeze
    REGEX_CAPTURE = "$".freeze
    OP_REPLACE = "=".freeze
    OP_APPEND = ">".freeze
    OP_PREPEND = "<".freeze
    OP_ADD = "+".freeze
    OP_SUB = "-".freeze

    attr_accessor :escape_wildcards
    attr_accessor :escape_operators
    attr_accessor :escape_regex
    attr_accessor :escape_regex_capture

    def initialize(src)
      @src = src
      @end = src.size - 1
      @start_i = 0
      @i = 0
    end

    def reset_escapes!
      self.escape_wildcards = false
      self.escape_operators = true
      self.escape_regex = false
      self.escape_regex_capture = true
    end

    def next
      return Token.new(@i, Tokens::EOF) if @i > @end
      char = @src[@i]
      case char
      when EXP_OPEN
        @i += 1
        token! Tokens::EXP_OPEN
      when EXP_CLOSE
        @i += 1
        token! Tokens::EXP_CLOSE
      when WILDCARD
        @i += 1
        token! Tokens::WILDCARD
      when REGEX_DELIM
        if @escape_regex
          get_str!
        else
          @i += 1
          token! Tokens::REG_DELIM
        end
      when REGEX_CAPTURE
        if @escape_regex_capture
          get_str!
        else
          @i += 1
          token! Tokens::REG_CAPTURE, char
        end
      when OP_REPLACE, OP_APPEND, OP_PREPEND, OP_ADD, OP_SUB
        if @escape_operators
          get_str!
        else
          @i += 1
          token! Tokens::OPERATOR, char
        end
      else
        get_str!
      end
    end

    private

    def token!(type, val = nil)
      t = Token.new(@start_i, type, val)
      @start_i = @i
      t
    end

    def get_str!
      str = ""
      escape, found_end = false, false
      until found_end or @i > @end
        char = @src[@i]

        if escape
          @i += 1
          str << char
          escape = false
          next
        end

        case char
        when ESCAPE
          @i += 1
          escape = true
        when EXP_OPEN
          found_end = true
        when EXP_CLOSE
          found_end = true
        when WILDCARD
          if @escape_wildcards
            @i += 1
            str << char
          else
            found_end = true
          end
        when REGEX_DELIM
          if @escape_regex
            @i += 1
            str << char
          else
            found_end = true
          end
        when REGEX_CAPTURE
          if @escape_regex_capture
            @i += 1
            str << char
          else
            found_end = true
          end
        when OP_REPLACE, OP_APPEND, OP_PREPEND, OP_ADD, OP_SUB
          if @escape_operators
            @i += 1
            str << char
          else
            found_end = true
          end
        else
          @i += 1
          str << char
        end
      end

      raise Error, "Trailing escape" if escape
      token! Tokens::TEXT, str
    end
  end
end
