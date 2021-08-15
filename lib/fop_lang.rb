require_relative 'fop/version'
require_relative 'fop/program'

module Fop
  def self.compile(src)
    Program.new(src)
  end
end
