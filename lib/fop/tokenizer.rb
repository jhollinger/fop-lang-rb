require_relative 'tokens'

module Fop
  class Tokenizer
    Token = Struct.new(:pos, :type, :val)
    Error = Struct.new(:pos, :message)
    Escapes = Struct.new(:operators, :regex_capture, :regex, :regex_escape, :wildcards, :exp)

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

    #
    # Controls which "mode" the tokenizer is currently in. This is a necessary result of the syntax lacking
    # explicit string delimiters. That *could* be worked around by requiring users to escape all reserved chars,
    # but that's ugly af. Instead, the parser continually assesses the current context and flips these flags on
    # or off to auto-escape certain chars for the next token.
    #
    attr_reader :escape

    def initialize(src)
      @src = src
      @end = src.size - 1
      @start_i = 0
      @i = 0
      reset_escapes!
    end

    # Auto-escape operators and regex capture vars. Appropriate for top-level syntax.
    def reset_escapes!
      @escape = Escapes.new(true, true)
    end

    # Auto-escape anything you'd find in a regular expression
    def regex_mode!
      @escape.regex = false # look for the final /
      @escape.regex_escape = true # pass \ through to the regex engine UNLESS it's followed by a /
      #@escape.regex_escape = true # escape any \ UNLESS it's followed by / (allows escaping of regex special like { and } without double escaping)
      @escape.wildcards = true
      @escape.operators = true
      @escape.regex_capture = true
      @escape.exp = true
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
        token! Tokens::WILDCARD, WILDCARD
      when REGEX_DELIM
        if @escape.regex
          get_str!
        else
          @i += 1
          token! Tokens::REG_DELIM
        end
      when REGEX_CAPTURE
        if @escape.regex_capture
          get_str!
        else
          @i += 1
          t = token! Tokens::REG_CAPTURE, @src[@i]
          @i += 1
          @start_i = @i
          t
        end
      when OP_REPLACE, OP_APPEND, OP_PREPEND, OP_ADD, OP_SUB
        if @escape.operators
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
          if @escape.regex_escape and @src[@i] != REGEX_DELIM
            str << char
          else
            escape = true
          end
        when EXP_OPEN
          if @escape.exp
            @i += 1
            str << char
          else
            found_end = true
          end
        when EXP_CLOSE
          if @escape.exp
            @i += 1
            str << char
          else
            found_end = true
          end
        when WILDCARD
          if @escape.wildcards
            @i += 1
            str << char
          else
            found_end = true
          end
        when REGEX_DELIM
          if @escape.regex
            @i += 1
            str << char
          else
            found_end = true
          end
        when REGEX_CAPTURE
          if @escape.regex_capture
            @i += 1
            str << char
          else
            found_end = true
          end
        when OP_REPLACE, OP_APPEND, OP_PREPEND, OP_ADD, OP_SUB
          if @escape.operators
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

      return Token.new(@i - 1, Tokens::TR_ESC) if escape
      token! Tokens::TEXT, str
    end
  end
end
