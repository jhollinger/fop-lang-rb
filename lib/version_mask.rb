require_relative 'version_mask/version'
require_relative 'version_mask/mask'

module VersionMask
  def self.parse(mask)
    Mask.new(mask)
  end
end
