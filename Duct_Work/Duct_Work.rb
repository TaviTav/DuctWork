# duct_work.rb
# Version Beta 3

require 'sketchup.rb'
require 'su_dynamiccomponents.rb'
require_relative 'Elbow v8.rb'
require_relative 'Reduction v5.rb'
require_relative 'Tee v4.rb'
require_relative 'Pants v4.rb'
require_relative 'Step v5.rb'
require_relative 'SC v2.rb'
require_relative 'Duct v1.rb'
require_relative 'Cap v1.rb'

# Define the module and method for creating the menu items
module Tav_Extensions
  module Duct_Work

    # sketchy bug fix? Anyway, at least it's working.
    # https://forums.sketchup.com/t/ruby-errors-in-dynamic-components/11530/11
    class Sketchup::Model
      unless method_defined?(:deleted?)
        def deleted?()
          self.valid?() ? false : true
        end
      end
    end

    # Create a menu item under the "DuctWork" menu
    def self.create_menu_item(item_name, &block)
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

    # Done
    def self.section_change_function
      SC.run
    end

    # Done
    def self.duct_function
      Duct.run
    end

    # Done
    def self.cap_function
      Cap.run
    end

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
      create_menu_item('Duct', &method(:duct_function))
      create_menu_item('Elbow', &method(:elbow_function))
      create_menu_item('Reduction', &method(:reduction_function))
      create_menu_item('Tee', &method(:tee_function))
      create_menu_item('Pants', &method(:ramification_pants_function))
      create_menu_item('Step/Offset', &method(:step_function))
      create_menu_item('Section Change', &method(:section_change_function))
      create_menu_item('End Cap', &method(:cap_function))
      # create_menu_item('Ramification elbow elbow', &method(:ramification_elbow_elbow_function))
      create_menu_item('Help', &method(:help))
      
    end
  end
end