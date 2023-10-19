# Rectangular reduction
# Version Beta 5
# Bugs:
# To do: MORE TESTING IS REQUIRED !!!!

# v5 changes:
# Adding attributes to the component
# Small code improvements

require_relative 'AttrCreate.rb'

module Reduction
  def self.run

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    red_a     = 400
    red_b     = 200
    red_c     = 200
    red_d     = 400
    red_e     = 0
    red_f     = 0
    red_g     = 25
    red_g1    = 25
    red_l     = 250
    red_area  = 0.0
    filter_message      = false
    area_square_inches  = 0.0

    # Constants
    conversion_factor   = 0.00064516
    min_size            = 150
    min_g               = 25
    componentUnits      = 'CENTIMETERS'
    redItemCode         = 'RED'

    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'B [mm]:', 'C [mm]:', 'D [mm]:', 'E [mm]:', 'F [mm]:', 'G [mm]:', 'G1 [mm]:', 'L [mm]:']
      results = UI.inputbox(prompts, defaults, 'Enter Values for Reduction')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input values
      input_defaults = [red_a, red_b, red_c, red_d, red_e, red_f, red_g, red_g1, red_l]
      user_input = get_user_input(input_defaults)

      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 9
        filter_message = true
        return
      end

      # Extract values from user input
      red_a, red_b, red_c, red_d, red_e, red_f, red_g, red_g1, red_l = user_input[0..8].map { |value| value }

      # Check if values are valid
      # A, B, C, D, L >= 100 mm, 
      # G, G1 > 0 
      if  red_a < min_size && red_b < min_size && red_c < min_size && red_d < min_size && 
          red_g < min_g && red_g1 < min_g && red_l < min_size 
        msg = 
        'Invalid values detected!!! 
        
        Check the following conditions:
        A, B, C, D, L > ' + min_size.to_s.gsub(/\s+/, "") +  
        'G, G1 >= ' + min_g.to_s.gsub(/\s+/, "") + 
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Create a new group & Get the group entities
      group = model.active_entities.add_group
      group_entities = group.entities

      # Make values available as length
      red_a     = red_a.mm
      red_b     = red_b.mm
      red_c     = red_c.mm
      red_d     = red_d.mm
      red_e     = red_e.mm
      red_f     = red_f.mm
      red_g     = red_g.mm
      red_g1    = red_g1.mm
      red_l     = red_l.mm

      # Create the geometry inside the group
      point1  = Geom::Point3d.new(red_a, 0, 0)
      point2  = Geom::Point3d.new(red_a, red_g, 0)
      point3  = Geom::Point3d.new(0, red_g, 0)
      point4  = Geom::Point3d.new(0, 0, red_b)
      point5  = Geom::Point3d.new(red_a, 0, red_b)
      point6  = Geom::Point3d.new(0, red_g, red_b)
      point7  = Geom::Point3d.new(red_a, red_g, red_b)
      point8  = Geom::Point3d.new(red_e, red_l - red_g1, red_f)
      point9  = Geom::Point3d.new(red_e + red_c, red_l - red_g1, red_f)
      point10 = Geom::Point3d.new(red_e, red_l - red_g1, red_f + red_d)
      point11 = Geom::Point3d.new(red_e + red_c, red_l - red_g1, red_f + red_d)
      point12 = Geom::Point3d.new(red_e, red_l, red_f)
      point13 = Geom::Point3d.new(red_e + red_c, red_l, red_f)
      point14 = Geom::Point3d.new(red_e, red_l, red_f + red_d)
      point15 = Geom::Point3d.new(red_e + red_c, red_l, red_f + red_d)

      face1   = group_entities.add_face ORIGIN, point1, point2, point3
      face2   = group_entities.add_face ORIGIN, point3, point6, point4
      face3   = group_entities.add_face point4, point5, point7, point6
      face4   = group_entities.add_face point1, point2, point7, point5
      face5   = group_entities.add_face point2, point9, point8, point3
      face6   = group_entities.add_face point3, point8, point10, point6
      face7   = group_entities.add_face point2, point7, point11, point9
      face8   = group_entities.add_face point6, point7, point11, point10
      face9   = group_entities.add_face point8, point9, point13, point12
      face10  = group_entities.add_face point8, point12, point14, point10
      face11  = group_entities.add_face point11, point15, point13, point9
      face12  = group_entities.add_face point10, point14, point15, point11

      # Calculate the reduction area
      group.entities.grep(Sketchup::Face).each do |face|
        area_square_inches += face.area
      end
      red_area = area_square_inches * conversion_factor

      # Set the name of the group, example: -RED A_400 B_200 C_200 D_400 E_0 F_0 G_25 G1_25 L_250 Area_0.3497
      red_a_str       = red_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_b_str       = red_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_c_str       = red_c.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_d_str       = red_d.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_e_str       = red_e.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_f_str       = red_f.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_g_str       = red_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_g1_str      = red_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_l_str       = red_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      red_area_str    = red_area.round(4).to_s

      red_group_name  = "-" + redItemCode + " A_" + red_a_str + 
                        " B_"     + red_b_str + 
                        " C_"     + red_c_str + 
                        " D_"     + red_d_str + 
                        " E_"     + red_e_str + 
                        " F_"     + red_f_str + 
                        " G_"     + red_g_str + 
                        " G1_"    + red_g1_str + 
                        " L_"     + red_l_str + 
                        " Area_"  + red_area_str

      # Check if the component is present in the model
      existing_component = model.definitions[red_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[red_group_name], trans)
          number = Sketchup.active_model.definitions[red_group_name].count_instances
          component_new_instance.name = number.to_s
      else # Add component and it's attributes
        component_instance = group.to_component
        comp_def = component_instance.definition
        comp_def.name = red_group_name

        AttrCreate.CreateGeneralAttributes(comp_def, componentUnits, redItemCode)

        AttrCreate.CreateDimensionAttributes(comp_def, 'a', red_a_str, 'STRING', 'A', 'A[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'b', red_b_str, 'STRING', 'B', 'B[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'c', red_c_str, 'STRING', 'C', 'C[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'd', red_d_str, 'STRING', 'D', 'D[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'e', red_e_str, 'STRING', 'E', 'E[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'f', red_f_str, 'STRING', 'F', 'F[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g', red_g_str, 'STRING', 'G', 'G[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g1', red_g1_str, 'STRING', 'G1', 'G1[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'l', red_l_str, 'STRING', 'L', 'L[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'uarea', red_area_str, 'STRING', 'Area', 'Area[m2]', 'VIEW')

        AttrCreate.CreateFormulaAttributes(comp_def, 'uairspeed', 'STRING', 'uAirSpeed', 'Air Speed[m/s]', 'VIEW', 'uairflow/3600/(smallest(a*b,c*d)/1000000)')

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
# Reduction.run