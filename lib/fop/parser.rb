require_relative 'tokenizer'
require_relative 'nodes'

module Fop
  SyntaxError = Struct.new(:token, :message)
  NameError = Struct.new(:token, :message)
  ArgError = Struct.new(:token, :message)
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
    OPS_WITH_OPTIONAL_ARGS = [Tokenizer::OP_REPLACE]

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
          nodes << parse_exp!(wildcard)
          wildcard = false
        when Tokens::REG_DELIM
          nodes << parse_regex!(wildcard)
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

    def parse_exp!(wildcard = false)
      exp = Nodes::Expression.new(wildcard)
      parse_exp_match! exp
      op_token = parse_exp_operator! exp
      if op_token
        parse_exp_arg! exp, op_token
      end
      return exp
    end

    def parse_exp_match!(exp)
      @tokenizer.escape.operators = false
      t = @tokenizer.next
      case t.type
      when Tokens::TEXT, Tokens::WILDCARD
        exp.match = t.val
        if (src = REGEX_MATCHES[exp.match])
          reg = Regexp.new((exp.wildcard ? REGEX_LAZY_WILDCARD : REGEX_START) + src)
          exp.regex = Nodes::Regex.new(src, reg)
        else
          errors << NameError.new(t, "Unknown match type '#{exp.match}'") if exp.regex.nil?
        end
      when Tokens::REG_DELIM
        exp.regex = parse_regex!(exp.wildcard)
        exp.match = exp.regex&.src
        exp.regex_match = true
        @tokenizer.reset_escapes!
      else
        errors << SyntaxError.new(t, "Unexpected #{t.type}; expected a string or a regex")
      end
    end

    def parse_exp_operator!(exp)
      @tokenizer.escape.operators = false
      t = @tokenizer.next
      case t.type
      when Tokens::EXP_CLOSE
        # no op
      when Tokens::OPERATOR
        exp.operator = t.val
      else
        errors << SyntaxError.new(t, "Unexpected #{t.type}; expected an operator")
      end
    end

    def parse_exp_arg!(exp, op_token)
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

      if exp.args.size != 1 and !OPS_WITH_OPTIONAL_ARGS.include?(exp.operator)
        errors << ArgError.new(op_token, "Operator '#{op_token.val}' requires an argument")
      end
    end

    def parse_regex!(wildcard = false)
      @tokenizer.regex_mode!
      reg = Nodes::Regex.new

      t = @tokenizer.next
      if t.type == Tokens::TEXT
        reg.src = (wildcard ? REGEX_LAZY_WILDCARD : REGEX_START) + t.val
        begin
          reg.regex = Regexp.new(reg.src)
        rescue RegexpError => e
          errors << RegexError.new(t, e.message)
        end
      else
        errors << SyntaxError.new(t, "Unexpected #{t.type}; expected a string of regex")
      end

      t = @tokenizer.next
      errors << SyntaxError.new(t, "Unexpected #{t.type}; expected a string of regex") unless t.type == Tokens::REG_DELIM
      reg
    end
  end
end
