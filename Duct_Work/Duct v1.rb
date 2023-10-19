# Rectangular Duct
# Version Beta 1
# Bugs:
# To do: Don't change anything yet, it's good how it is

# v.X changes:

require_relative 'AttrCreate.rb'

module Duct
  def self.run

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    duc_a               = 400
    duc_b               = 200
    duc_l               = 1500
    filter_message      = false

    # Constants
    conversion_factor   = 0.00064516
    min_size            = 150
    min_l               = 100
    componentUnits      = 'CENTIMETERS'
    ductItemCode        = 'CRD'
    duc_group_name      = '-' + ductItemCode + ' Rectangular Duct'


    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'B [mm]:', 'L [mm]:']
      results = UI.inputbox(prompts, defaults, 'Enter Values for Duct')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input values
      input_defaults = [duc_a, duc_b, duc_l]
      user_input = get_user_input(input_defaults)

      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 3
        filter_message = true
        return
      end

      # Extract values from user input
      duc_a, duc_b, duc_l = user_input[0..2].map { |value| value }

      # Check if values are valid
      # A, B >= 150 mm, 
      # L >= 100 
      if  duc_a < min_size && duc_b < min_size && duc_l < min_l 
        msg = 
        'Invalid values detected!!! 
        
        Check the following conditions:
        A, B >= ' + min_size.to_s.gsub(/\s+/, "") +  
        'L >= ' + min_l.to_s.gsub(/\s+/, "") + 
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Create a new group
      group = model.active_entities.add_group
      
      # Get the group entities
      group_entities = group.entities

      # Make values available as length and string
      duc_a     = duc_a.mm
      duc_b     = duc_b.mm
      duc_l     = duc_l.mm
      duc_a_str       = duc_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      duc_b_str       = duc_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      duc_l_str       = duc_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")

      # Create the geometry inside the group
      point1  = Geom::Point3d.new(duc_a, 0, 0)
      point2  = Geom::Point3d.new(duc_a, duc_l, 0)
      point3  = Geom::Point3d.new(0, duc_l, 0)
      point4  = Geom::Point3d.new(0, 0, duc_b)
      point5  = Geom::Point3d.new(0, duc_l, duc_b)
      face1   = group_entities.add_face ORIGIN, point1, point2, point3
      face1.pushpull(- duc_b)

      # Identify the 2 faces to delete then delete them
      # face1 is defined by ORIGIN, point1, point4
      # face2 is defined by point2, point3, point5
      face1, face2 = nil, nil
      group.entities.grep(Sketchup::Face).each do |face|
        if  face.classify_point(ORIGIN)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point1)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point4)   == Sketchup::Face::PointOnVertex && 
          face1 = face
        end
        if  face.classify_point(point2)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point3)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point5)   == Sketchup::Face::PointOnVertex && 
          face2 = face
        end
      end
      face1.erase!
      face2.erase!

      # Check if the component is present in the model
      existing_component = model.definitions[duc_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[duc_group_name], trans)
          number = Sketchup.active_model.definitions[duc_group_name].count_instances
          component_new_instance.name = number.to_s
      else # Add component and it's attributes
        component_instance = group.to_component
        comp_def = component_instance.definition
        comp_def.name = duc_group_name

        AttrCreate.CreateGeneralAttributes(comp_def, componentUnits, ductItemCode)

        AttrCreate.CreateDimensionAttributes(comp_def, 'a', duc_a_str, 'STRING', 'A', 'A[mm]', 'TEXTBOX')
        AttrCreate.CreateDimensionAttributes(comp_def, 'b', duc_b_str, 'STRING', 'B', 'B[mm]', 'TEXTBOX')
        AttrCreate.CreateDimensionAttributes(comp_def, 'l', duc_l_str, 'STRING', 'L', 'L[mm]', 'TEXTBOX')

        AttrCreate.CreateFormulaAttributes(comp_def, 'uarea', 'STRING', 'uArea', 'Area[m2]', 'VIEW', '(2*a+2*b)*l/1000000')
        AttrCreate.CreateFormulaAttributes(comp_def, 'uairspeed', 'STRING', 'uAirSpeed', 'Air Speed[m/s]', 'VIEW', 'uairflow/3600/(a/1000)/(b/1000)')

        comp_def.set_attribute 'dynamic_attributes', '_lenx_units', 'CENTIMETERS'
        comp_def.set_attribute 'dynamic_attributes', '_lenx', duc_a.to_cm
        comp_def.set_attribute 'dynamic_attributes', '_lenx_label', 'LenX'
        comp_def.set_attribute 'dynamic_attributes', '_lenx_access', 'VIEW'
        comp_def.set_attribute 'dynamic_attributes', '_lenx_formula', 'a/10.0'

        comp_def.set_attribute 'dynamic_attributes', '_leny_units', 'CENTIMETERS'
        comp_def.set_attribute 'dynamic_attributes', '_leny', duc_l.to_cm
        comp_def.set_attribute 'dynamic_attributes', '_leny_label', 'LenY'
        comp_def.set_attribute 'dynamic_attributes', '_leny_access', 'VIEW'
        comp_def.set_attribute 'dynamic_attributes', '_leny_formula', 'l/10'

        comp_def.set_attribute 'dynamic_attributes', '_lenz_units', 'CENTIMETERS'
        comp_def.set_attribute 'dynamic_attributes', '_lenz', duc_b.to_cm
        comp_def.set_attribute 'dynamic_attributes', '_lenz_label', 'LenZ'
        comp_def.set_attribute 'dynamic_attributes', '_lenz_access', 'VIEW'
        comp_def.set_attribute 'dynamic_attributes', '_lenz_formula', 'b/10'

        dcs = $dc_observers.get_latest_class
        dcs.redraw_with_undo(component_instance)
      end

    rescue => e
      # filter some common errors and do not message the user
      if !filter_message
        UI.messagebox("Grrrr some unknown error occurred: #{e.message}") 
      else
        # nothing here
      end
    end # End Main Code

  end # def self.run

end # Module

### Test!!! Don't forget to comment this line !!! ###
#Duct.run