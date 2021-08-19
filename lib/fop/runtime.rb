module Fop
  class Runtime
    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    def apply(input)
      input = input.clone
      output =
        @nodes.reduce("") { |acc, node|
          section = node.consume!(input)
          return nil if section.nil?
          acc + section.to_s
        }
      input.empty? ? output : nil
    end
  end
end
