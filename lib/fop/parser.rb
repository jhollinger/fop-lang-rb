require_relative 'tokenizer'
require_relative 'nodes'

module Fop
  SyntaxError = Struct.new(:token, :message)
  NameError = Struct.new(:token, :message)
  RegexError = Struct.new(:token, :message)
    #EXP_REPLACE = ->(_val, _op, arg) { arg || BLANK }
    #EXP_MATH = ->(val, op, arg) { val.to_i.send(op, arg.to_i) }
    #EXP_APPEND = ->(val, _op, arg) { val + arg }
    #EXP_PREPEND = ->(val, _op, arg) { arg + val }

  class Parser
    DIGIT = /^[0-9]$/
    REGEX_START = "^".freeze
    REGEX_LAZY_WILDCARD = ".*?".freeze
    REGEX_MATCHES = {
      "N" => "[0-9]+".freeze,
      "W" => "\\w+".freeze,
      "A" => "[a-zA-Z]+".freeze,
      "*" => ".*".freeze,
    }.freeze

    attr_reader :errors

    def initialize(src, debug: false)
      @tokenizer = Tokenizer.new(src)
      @errors = []
    end

    def parse
      nodes = []
      wildcard = false
      eof = false
      # Top-level parsing. It will always be looking for a String, Regex, or Expression.
      until eof
        @tokenizer.reset_escapes!
        t = @tokenizer.next
        case t.type
        when Tokens::WILDCARD
          errors << SyntaxError.new(t, "Consecutive wildcards") if wildcard
          wildcard = true
        when Tokens::TEXT
          nodes << Nodes::Text.new(wildcard, t.val)
          wildcard = false
        when Tokens::EXP_OPEN
          nodes << parse_exp!(t, wildcard)
          wildcard = false
        when Tokens::REG_DELIM
          nodes << parse_regex!(t, wildcard)
          wildcard = false
        when Tokens::EOF
          eof = true
        else
          errors << SyntaxError.new(t, "Unexpected #{t.type}")
        end
      end

      if wildcard
        nodes << Nodes::Text.new(true, "")
      end

      return nodes, @errors
    end

    def parse_exp!(t, wildcard = false)
      exp = Nodes::Expression.new

      # Find the match pattern
      @tokenizer.escape.operators = false
      t = @tokenizer.next
      case t.type
      when Tokens::TEXT, Tokens::WILDCARD
        exp.match = t.val
        if (reg = REGEX_MATCHES[exp.match])
          exp.regex_src = (wildcard ? REGEX_LAZY_WILDCARD : REGEX_START) + reg
        else
          errors << NameError.new(t, "Unknown match type '#{exp.match}'") if exp.regex.nil?
        end
      when Tokens::REG_DELIM
        reg = parse_regex!(t, wildcard)
        exp.match = reg.src
        exp.regex_src = reg.src
        @tokenizer.reset_escapes!
      else
        errors << SyntaxError.new(t, "Unexpected #{t.type}; expected a string or a regex")
      end

      # Find the operator (if any)
      @tokenizer.escape.operators = false
      t = @tokenizer.next
      case t.type
      when Tokens::EXP_CLOSE
        return exp
      when Tokens::OPERATOR
        exp.operator = t.val
      else
        errors << SyntaxError.new(t, "Unexpected #{t.type}; expected an operator")
      end

      # Find the argument (if any)
      @tokenizer.escape.operators = true
      @tokenizer.escape.regex = true
      @tokenizer.escape.regex_capture = false if exp.regex_src
      found_close, eof = false, false
      until found_close or eof
        t = @tokenizer.next
        case t.type
        when Tokens::TEXT
          exp.args << t.val
        when Tokens::REGEX_CAPTURE
          exp.args << t.val.to_i
          errors << SyntaxError.new(t, "Invalid regex capture; must be between 0 and 9") unless t.val =~ DIGIT
          errors << SyntaxError.new(t, "Unexpected regex capture; expected str or '}'") if !exp.regex_src
        when Tokens::EXP_CLOSE
          found_close = true
        when Tokens::EOF
          eof = true
          errors << SyntaxError.new(t, "Unexpected #{t.type}; expected str or '}'")
        else
          errors << SyntaxError.new(t, "Unexpected #{t.type}; expected str or '}'")
        end
      end
      return exp
    end

    def parse_regex!(t, wildcard = false)
      @tokenizer.regex_mode!
      reg = Nodes::Regex.new

      t = @tokenizer.next
      if t.type == Tokens::TEXT
        reg.src = (wildcard ? REGEX_LAZY_WILDCARD : REGEX_START) + t.val
      else
        errors << SyntaxError.new(t, "Unexpected #{t.type}; expected a string of regex")
      end

      t = @tokenizer.next
      errors << SyntaxError.new(t, "Unexpected #{t.type}; expected a string of regex") unless t.type == Tokens::REG_DELIM

      reg
    end

=begin
    def parse_regex_str!(wildcard, t, src = t.val)
      prefix = wildcard ? REGEX_LAZY_WILDCARD : REGEX_START
      Regexp.new(prefix + src)
    rescue RegexpError => e
      errors << RegexError.new(t, e.message)
      nil
    end
=end
  end
end
