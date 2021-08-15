require_relative 'fop/version'
require_relative 'fop/program'

def Fop(src)
  ::Fop::Program.new(src)
end

module Fop
  def self.compile(src)
    Program.new(src)
  end
end
