require 'sketchup.rb'
require 'extensions.rb'

module Tav_Extensions
  module Duct_Work
    ### CONSTANTS ###

    # Extension information
    EXT_NAME              = "Duct Work"
    EXT_VERSION           = "1.0"
    EXT_TITLE             = "Rectangular air duct systems"
    EXT_DESCRIPTION       = "This extension helps HVAC engineers to build duct systems"

    # Resource paths
    file = __FILE__.dup
    file.force_encoding("UTF-8") if file.respond_to?(:force_encoding)
    FILENAMESPACE = File.basename(file, '.*')
    PATH_ROOT     = File.dirname(file).freeze
    PATH          = File.join(PATH_ROOT, FILENAMESPACE).freeze

    ### EXTENSION ###    

    unless file_loaded?(__FILE__)
      loader = File.join(PATH , 'Duct_Work.rb')
      extension             = SketchupExtension.new(EXT_NAME, loader)
      extension.copyright   = "Copyright #{Time.now.year} Tavi_Tav"
      extension.creator     = "Tavi_Tav"
      extension.version     = EXT_VERSION
      extension.description = EXT_DESCRIPTION
      Sketchup.register_extension(extension, true)
    end
  end  # module Duct_Work
end  # module Tav_Extensions