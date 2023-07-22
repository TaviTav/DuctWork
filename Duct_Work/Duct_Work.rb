# duct_work.rb
# Version Beta 2

require 'sketchup.rb'
require_relative 'Elbow v7.rb'
require_relative 'Reduction v4.rb'
require_relative 'Tee v3.rb'
require_relative 'Pants v3.rb'
require_relative 'Step v4.rb'

# Define the module and method for creating the menu items
module Tav_Extensions
  module Duct_Work
    def self.create_menu_item(item_name, &block)
      # Create a menu item under the "DuctWork" menu
      menu = @menu.add_item(item_name, &block)
    end

    # Done
    def self.elbow_function
      Elbow.run
    end

    # Done
    def self.reduction_function
      Reduction.run
    end

    # Done
    def self.tee_function
      Tee.run
    end

    # Done
    def self.ramification_pants_function
      Pants.run
    end

    # Done
    def self.step_function
      Step.run
    end

    # # Work in progress
    # def self.ramification_elbow_channel_function
    #   UI.messagebox('Ramification elbow channel menu item clicked!')
    #   # Add your ramification elbow channel functionality here
    #   # ...
    # end

    # # Work in progress
    # def self.ramification_elbow_elbow_function
    #   UI.messagebox('Ramification elbow elbow menu item clicked!')
    #   # Add your ramification elbow elbow functionality here
    #   # ...
    # end

    # Work in progress
    def self.help
      UI.messagebox('For documentation visit:
        https://github.com/TaviTav/DuctWork')
    end
    
    # Create the menu items when the extension is loaded
    unless file_loaded?(__FILE__)
      @menu = UI.menu('Plugins').add_submenu('DuctWork')
      create_menu_item('Elbow', &method(:elbow_function))
      create_menu_item('Reduction', &method(:reduction_function))
      create_menu_item('Tee', &method(:tee_function))
      create_menu_item('Pants', &method(:ramification_pants_function))
      create_menu_item('Step', &method(:step_function))
      # create_menu_item('Ramification elbow channel', &method(:ramification_elbow_channel_function))
      # create_menu_item('Ramification elbow elbow', &method(:ramification_elbow_elbow_function))
      create_menu_item('Help', &method(:help))
      
    end
  end
end