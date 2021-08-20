require_relative 'parser'

module Fop
  module Compiler
    def self.compile(src)
      parser = Parser.new(src)
      nodes, errors = parser.parse

      instructions = nodes.map { |node|
        case node
        when Nodes::Text, Nodes::Regex
          Instructions.regex_match(node.regex)
        when Nodes::Expression
          Instructions::ExpressionMatch.new(node)
        else
          raise "Unknown node type #{node}"
        end
      }

      return nil, errors if errors.any?
      return instructions, nil
    end

    module Instructions
      BLANK = "".freeze
      OPERATIONS = {
        "=" => ->(_val, arg) { arg || BLANK },
        "+" => ->(val, arg) { val.to_i + arg.to_i },
        "-" => ->(val, arg) { val.to_i - arg.to_i },
        ">" => ->(val, arg) { val + arg },
        "<" => ->(val, arg) { arg + val },
      }

      def self.regex_match(regex)
        ->(input) { input.slice! regex }
      end

      class ExpressionMatch
        def initialize(node)
          @regex = node.regex&.regex
          @op = node.operator ? OPERATIONS.fetch(node.operator) : nil
          @regex_match = node.regex_match
          if node.arg&.any? { |a| a.is_a? Integer }
            @arg, @arg_with_caps = nil, node.arg
          else
            @arg = node.arg&.join("")
            @arg_with_caps = nil
          end
        end

        def call(input)
          if (match = @regex.match(input))
            val = match.to_s
            blank = val == BLANK
            input.sub!(val, BLANK) unless blank
            found_val = @regex_match || !blank
            arg = @arg_with_caps ? sub_caps(@arg_with_caps, match.captures) : @arg
            @op && found_val ? @op.call(val, arg) : val
          end
        end

        private

        def sub_caps(args, caps)
          args.map { |a|
            a.is_a?(Integer) ? caps[a].to_s : a
          }.join("")
        end
      end
    end
  end
end
