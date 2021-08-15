require_relative 'nodes'

module Fop
  module Parser
    Error = Class.new(StandardError)

    def self.parse!(tokens)
      stack = []
      current_el = nil

      tokens.each { |token|
        case current_el
        when nil
          current_el = new_element token
        when :wildcard
          current_el = new_element token, true
          raise Error, "Unexpected * after wildcard" if current_el == :wildcard
        when Nodes::Text
          current_el = parse_text stack, current_el, token
        when Nodes::Match
          current_el = parse_match stack, current_el, token
        else
          raise Error, "Unexpected token #{token} in #{current_el}"
        end
      }

      case current_el
      when nil
        # noop
      when :wildcard
        stack << Nodes::Text.new(true, "")
      when Nodes::Text
        stack << current_el
      when Nodes::Match
        raise Error, "Unclosed match"
      end

      stack
    end

    private

    def self.new_element(token, wildcard = false)
      case token
      when Tokenizer::Char
        Nodes::Text.new(wildcard, token.char.clone)
      when :match_open
        Nodes::Match.new(wildcard, [])
      when :match_close
        raise ParserError, "Unmatched }"
      when :wildcard
        :wildcard
      else
        raise ParserError, "Unexpected #{token}"
      end
    end

    def self.parse_text(stack, text_el, token)
      case token
      when :match_open
        stack << text_el
        Nodes::Match.new(false, [])
      when :match_close
        raise ParserError.new, "Unexpected }"
      when Tokenizer::Char
        text_el.str << token.char
        text_el
      when :wildcard
        stack << text_el
        :wildcard
      else
        raise ParserError, "Unexpected #{token}"
      end
    end

    def self.parse_match(stack, match_el, token)
      case token
      when Tokenizer::Char
        match_el.tokens << token
        match_el
      when :wildcard
        match_el.tokens << Tokenizer::Char.new("*").freeze
        match_el
      when :match_close
        match_el.parse!
        stack << match_el
        nil
      else
        raise ParserError, "Unexpected #{token}"
      end
    end
  end
end
