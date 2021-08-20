module Fop
  class Program
    def initialize(instructions)
      @instructions = instructions
    end

    def apply(input)
      input = input.clone
      output =
        @instructions.reduce("") { |acc, ins|
          result = ins.call(input)
          return nil if result.nil?
          acc + result.to_s
        }
      input.empty? ? output : nil
    end
  end
end
