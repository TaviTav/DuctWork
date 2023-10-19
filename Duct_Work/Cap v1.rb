# Rectangular End Cap
# Version Beta 1
# Bugs:
# To do: Don't change anything yet, it's good how it is

# v.X changes:

require_relative 'AttrCreate.rb'

module Cap
  def self.run

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    dim_a               = 400
    dim_b               = 200
    dim_l               = 40
    filter_message      = false

    # Constants
    conversion_factor   = 0.00064516
    min_size            = 150
    min_l               = 40
    componentUnits      = 'CENTIMETERS'
    capItemCode        = 'CAP'
    cap_group_name      = '-' + capItemCode + ' Rectangular End Cap'

    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'B [mm]:']
      results = UI.inputbox(prompts, defaults, 'Enter Values for End Cap')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input values
      input_defaults = [dim_a, dim_b]
      user_input = get_user_input(input_defaults)

      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 2
        filter_message = true
        return
      end

      # Extract values from user input
      dim_a, dim_b = user_input[0..1].map { |value| value }

      # Check if values are valid
      # A, B >= 150 mm, 
      # L >= 40 
      if  dim_a < min_size && dim_b < min_size 
        msg = 
        'Invalid values detected!!! 
        
        Check the following conditions:
        A, B >= ' + min_size.to_s.gsub(/\s+/, "")  

        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Create a new group
      group = model.active_entities.add_group
      
      # Get the group entities
      group_entities = group.entities

      # Make values available as length and string
      dim_a     = dim_a.mm
      dim_b     = dim_b.mm
      dim_l     = dim_l.mm
      dim_a_str       = dim_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      dim_b_str       = dim_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      dim_l_str       = dim_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")

      # Create the geometry inside the group
      point1  = Geom::Point3d.new(dim_a, 0, 0)
      point2  = Geom::Point3d.new(dim_a, dim_l, 0)
      point3  = Geom::Point3d.new(0, dim_l, 0)
      point4  = Geom::Point3d.new(0, 0, dim_b)
      point5  = Geom::Point3d.new(0, dim_l, dim_b)
      face1   = group_entities.add_face ORIGIN, point1, point2, point3
      face1.pushpull(- dim_b)

      # Identify the face to delete then delete it
      # face1 is defined by ORIGIN, point1, point4

      face1 = nil
      group.entities.grep(Sketchup::Face).each do |face|
        if  face.classify_point(ORIGIN)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point1)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point4)   == Sketchup::Face::PointOnVertex && 
          face1 = face
        end
      end
      face1.erase!

      # Check if the component is present in the model
      existing_component = model.definitions[cap_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[cap_group_name], trans)
          number = Sketchup.active_model.definitions[cap_group_name].count_instances
          component_new_instance.name = number.to_s
      else # Add component and it's attributes
        component_instance = group.to_component
        comp_def = component_instance.definition
        comp_def.name = cap_group_name

        AttrCreate.CreateGeneralAttributes(comp_def, componentUnits, capItemCode)

        AttrCreate.CreateDimensionAttributes(comp_def, 'a', dim_a_str, 'STRING', 'A', 'A[mm]', 'TEXTBOX')
        AttrCreate.CreateDimensionAttributes(comp_def, 'b', dim_b_str, 'STRING', 'B', 'B[mm]', 'TEXTBOX')
        AttrCreate.CreateDimensionAttributes(comp_def, 'l', dim_l_str, 'STRING', 'L', 'L[mm]', 'VIEW')

        AttrCreate.CreateFormulaAttributes(comp_def, 'uarea', 'STRING', 'uArea', 'Area[m2]', 'VIEW', '((2*a+2*b)*l+a*b)/1000000')
        AttrCreate.CreateFormulaAttributes(comp_def, 'uairspeed', 'STRING', 'uAirSpeed', 'Air Speed[m/s]', 'VIEW', 'uairflow/3600/(a/1000)/(b/1000)')

        comp_def.set_attribute 'dynamic_attributes', '_lenx_units', 'CENTIMETERS'
        comp_def.set_attribute 'dynamic_attributes', '_lenx', dim_a.to_cm
        comp_def.set_attribute 'dynamic_attributes', '_lenx_label', 'LenX'
        comp_def.set_attribute 'dynamic_attributes', '_lenx_access', 'VIEW'
        comp_def.set_attribute 'dynamic_attributes', '_lenx_formula', 'a/10.0'

        comp_def.set_attribute 'dynamic_attributes', '_lenz_units', 'CENTIMETERS'
        comp_def.set_attribute 'dynamic_attributes', '_lenz', dim_b.to_cm
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
#Cap.run