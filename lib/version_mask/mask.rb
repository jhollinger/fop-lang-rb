require_relative 'tokenizer'
require_relative 'parser'

module VersionMask
  class Mask
    attr_reader :nodes

    def initialize(mask)
      tokens = Tokenizer.tokenize! mask
      @nodes = Parser.parse! tokens
    end

    def apply(input)
      input = input.clone
      output =
        @nodes.reduce("") { |acc, token|
          section = token.consume!(input)
          return nil if section.nil?
          acc + section.to_s
        }
      input.empty? ? output : nil
    end
  end
end
