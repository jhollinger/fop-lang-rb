require_relative 'nodes'

module Fop
  module Parser
    Error = Class.new(StandardError)

    MATCH_NUM = "N".freeze
    MATCH_WORD = "W".freeze
    MATCH_ALPHA = "A".freeze
    MATCH_WILD = "*".freeze
    BLANK = "".freeze
    OP_REPLACE = "=".freeze
    OP_ADD = "+".freeze
    OP_SUB = "-".freeze
    OP_MUL = "*".freeze
    OP_DIV = "/".freeze

    def self.parse!(tokens)
      nodes = []
      curr_node = nil

      tokens.each { |token|
        case curr_node
        when nil
          curr_node = new_node token
        when :wildcard
          curr_node = new_node token, true
          raise Error, "Unexpected * after wildcard" if curr_node == :wildcard
        when Nodes::Text
          curr_node, finished_node = parse_text curr_node, token
          nodes << finished_node if finished_node
        when Nodes::Op
          nodes << curr_node
          curr_node = new_node token
        else
          raise Error, "Unexpected node #{curr_node}"
        end
      }

      case curr_node
      when nil
        # noop
      when :wildcard
        nodes << Nodes::Text.new(true, "")
      when Nodes::Text, Nodes::Op
        nodes << curr_node
      else
        raise "Unexpected end node #{curr_node}"
      end

      nodes
    end

    private

    def self.new_node(token, wildcard = false)
      case token
      when Tokenizer::Char
        Nodes::Text.new(wildcard, token.char.clone)
      when Tokenizer::Op
        op = Nodes::Op.new(wildcard)
        parse_op! op, token
        op
      when :wildcard
        :wildcard
      else
        raise Error, "Unexpected #{token}"
      end
    end

    # @return current node
    # @return finished node
    def self.parse_text(node, token)
      case token
      when Tokenizer::Char
        node.str << token.char
        return node, nil
      when Tokenizer::Op
        op = new_node token
        return op, node
      when :wildcard
        return :wildcard, node
      else
        raise Error, "Unexpected #{token}"
      end
    end

    def self.parse_op!(node, token)
      # parse the matching type
      node.regex =
        case token.match
        when Tokenizer::Char
          node.match = token.match.char
          node.regex_match = false
          case node.match
          when MATCH_NUM then Regexp.new((node.wildcard ? ".*?" : "^") + "[0-9]+")
          when MATCH_WORD then Regexp.new((node.wildcard ? ".*?" : "^") + "\\w+")
          when MATCH_ALPHA then Regexp.new((node.wildcard ? ".*?" : "^") + "[a-zA-Z]+")
          when MATCH_WILD then /.*/
          else raise Error, "Unknown match type '#{node.match}'"
          end 
        when Tokenizer::Regex
          node.match = "/#{token.match.src}/"
          node.regex_match = true
          Regexp.new((node.wildcard ? ".*?" : "^") + token.match.src)
        when nil
          raise Error, "Empty operation"
        else
          raise Error, "Unexpected #{token.match}"
        end

      # parse the operator (if any)
      if token.operator
        raise Error, "Unexpected #{token.operator} for operator" unless token.operator.is_a? Tokenizer::Char
        node.operator = token.operator.char
        node.operator_arg = token.arg if token.arg and token.arg != BLANK
        node.expression =
          case node.operator
          when OP_REPLACE
            ->(_) { node.operator_arg || BLANK }
          when OP_ADD, OP_SUB, OP_MUL, OP_DIV
            raise Error, "Operator #{node.operator} is only available for numeric matches" unless node.match == MATCH_NUM
            raise Error, "Operator #{node.operator} expects an argument" if node.operator_arg.nil?
            ->(x) { x.to_i.send(node.operator, node.operator_arg.to_i) }
          else
            raise(Error, "Unknown operator #{node.operator}")
          end
      end
    end
  end
end
