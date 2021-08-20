require_relative 'tokenizer'
require_relative 'nodes'

module Fop
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
    TR_REGEX = /.*/

    Error = Struct.new(:type, :token, :message) do
      def to_s
        "#{type.to_s.capitalize} error: #{message} at column #{token.pos}"
      end
    end

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
          errors << Error.new(:syntax, t, "Consecutive wildcards") if wildcard
          wildcard = true
        when Tokens::TEXT
          reg = build_regex!(wildcard, t, Regexp.escape(t.val))
          nodes << Nodes::Text.new(wildcard, t.val, reg)
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
          errors << Error.new(:syntax, t, "Unexpected #{t.type}")
        end
      end
      nodes << Nodes::Text.new(true, "", TR_REGEX) if wildcard
      return nodes, @errors
    end

    def parse_exp!(wildcard = false)
      exp = Nodes::Expression.new(wildcard)
      parse_exp_match! exp
      op_token = parse_exp_operator! exp
      if exp.operator
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
          exp.regex = Nodes::Regex.new(exp.wildcard, src, reg)
        else
          errors << Error.new(:name, t, "Unknown match type '#{exp.match}'") if exp.regex.nil?
        end
      when Tokens::REG_DELIM
        exp.regex = parse_regex!(exp.wildcard)
        exp.match = exp.regex&.src
        exp.regex_match = true
        @tokenizer.reset_escapes!
      else
        errors << Error.new(:syntax, t, "Unexpected #{t.type}; expected a string or a regex")
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
        errors << Error.new(:syntax, t, "Unexpected #{t.type}; expected an operator")
      end
      t
    end

    def parse_exp_arg!(exp, op_token)
      @tokenizer.escape.operators = true
      @tokenizer.escape.regex = true
      @tokenizer.escape.regex_capture = false if exp.regex_match

      exp.arg = []
      found_close, eof = false, false
      until found_close or eof
        t = @tokenizer.next
        case t.type
        when Tokens::TEXT
          exp.arg << t.val
        when Tokens::REG_CAPTURE
          exp.arg << t.val.to_i - 1
          errors << Error.new(:syntax, t, "Invalid regex capture; must be between 0 and 9 (found #{t.val})") unless t.val =~ DIGIT
          errors << Error.new(:syntax, t, "Unexpected regex capture; expected str or '}'") if !exp.regex_match
        when Tokens::EXP_CLOSE
          found_close = true
        when Tokens::EOF
          eof = true
          errors << Error.new(:syntax, t, "Unexpected #{t.type}; expected str or '}'")
        else
          errors << Error.new(:syntax, t, "Unexpected #{t.type}; expected str or '}'")
        end
      end

      if exp.arg.size != 1 and !OPS_WITH_OPTIONAL_ARGS.include?(exp.operator)
        errors << Error.new(:arg, op_token, "Operator '#{op_token.val}' requires an argument")
      end
    end

    def parse_regex!(wildcard)
      @tokenizer.regex_mode!
      t = @tokenizer.next
      reg = Nodes::Regex.new(wildcard, t.val)
      if t.type == Tokens::TEXT
        reg.regex = build_regex!(wildcard, t)
      else
        errors << Error.new(:syntax, t, "Unexpected #{t.type}; expected a string of regex")
      end

      t = @tokenizer.next
      errors << Error.new(:syntax, t, "Unexpected #{t.type}; expected a string of regex") unless t.type == Tokens::REG_DELIM
      reg
    end

    def build_regex!(wildcard, token, src = token.val)
      Regexp.new((wildcard ? REGEX_LAZY_WILDCARD : REGEX_START) + src)
    rescue RegexpError => e
      errors << Error.new(:regex, token, e.message)
      nil
    end
  end
end
