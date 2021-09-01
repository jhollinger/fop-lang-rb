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
          arg_error = Validations.validate_args(node)
          errors << arg_error if arg_error
          Instructions::ExpressionMatch.new(node)
        else
          raise "Unknown node type #{node}"
        end
      }

      return nil, errors if errors.any?
      return instructions, nil
    end

    module Validations
      def self.validate_args(exp_node)
        op_token = exp_node.operator_token || return
        op = Instructions::OPERATIONS.fetch(op_token.val)
        num = exp_node.args&.size || 0
        arity = op.arity
        max_arity = op.max_arity || arity
        if num < arity or num > max_arity
          Parser::Error.new(:arg, op_token, "#{op_token.val} expects #{arity}..#{max_arity} arguments; #{num} given")
        end
      end
    end

    module Instructions
      Op = Struct.new(:proc, :arity, :max_arity)
      BLANK = "".freeze
      OPERATIONS = {
        "=" => Op.new(->(_val, args) { args[0] || BLANK }, 0, 1),
        "+" => Op.new(->(val, args) { val.to_i + args[0].to_i }, 1),
        "-" => Op.new(->(val, args) { val.to_i - args[0].to_i }, 1),
        ">" => Op.new(->(val, args) { val + args[0] }, 1),
        "<" => Op.new(->(val, args) { args[0] + val }, 1),
      }

      def self.regex_match(regex)
        ->(input) { input.slice! regex }
      end

      class ExpressionMatch
        def initialize(node)
          @regex = node.regex&.regex
          @op = node.operator_token ? OPERATIONS.fetch(node.operator_token.val) : nil
          @regex_match = node.regex_match
          @args = node.args&.map { |arg|
            arg.has_captures ? arg.segments : arg.segments.join("")
          }
        end

        def call(input)
          if (match = @regex.match(input))
            val = match.to_s
            blank = val == BLANK
            input.sub!(val, BLANK) unless blank
            found_val = @regex_match || !blank
            if @op and @args and found_val
              args = @args.map { |arg|
                case arg
                when String then arg
                when Array then sub_caps(arg, match.captures)
                else raise "Unexpected arg type #{arg.class.name}"
                end
              }
              @op.proc.call(val, args)
            else
              val
            end
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
