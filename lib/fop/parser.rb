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
        parse_op! op, token.tokens
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

    def self.parse_op!(node, tokens)
      t = tokens[0] || raise(Error, "Empty operation")
      # parse the matching type
      node.regex =
        case t
        when Tokenizer::Char
          node.match = t.char
          node.regex_match = false
          case t.char
          when MATCH_NUM then Regexp.new((node.wildcard ? ".*?" : "^") + "[0-9]+")
          when MATCH_WORD then Regexp.new((node.wildcard ? ".*?" : "^") + "\\w+")
          when MATCH_ALPHA then Regexp.new((node.wildcard ? ".*?" : "^") + "[a-zA-Z]+")
          when MATCH_WILD then /.*/
          else raise Error, "Unknown match type '#{t.char}'"
          end 
        when Tokenizer::Regex
          node.match = "/#{t.src}/"
          node.regex_match = true
          Regexp.new((node.wildcard ? ".*?" : "^") + t.src)
        else
          raise Error, "Unexpected token #{t}"
        end

      # parse the operator (if any)
      if (op = tokens[1])
        raise Error, "Unexpected #{op}" unless op.is_a? Tokenizer::Char
        node.operator = op.char

        arg = tokens[2..-1].reduce("") { |acc, t|
          raise Error, "Unexpected #{t}" unless t.is_a? Tokenizer::Char
          acc + t.char
        }
        node.operator_arg = arg == BLANK ? nil : arg

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
