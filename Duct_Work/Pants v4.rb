# Rectangular pants
# Version Beta 4
# Bugs:
# To do: MORE TESTING IS REQUIRED !!!!

# v4 changes:
# Adding attributes to the component
# Small code improvements

require_relative 'AttrCreate.rb'

module Pants
  def self.run

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    pant_a    = 500
    pant_b    = 300
    pant_c    = 300
    pant_d    = 350
    pant_e    = 100
    pant_h    = 100
    pant_l    = 400
    pant_g    = 25
    pant_g1   = 25 
    pant_area = 0.0
    filter_message      = false
    area_square_inches  = 0.0

    # Constants
    conversion_factor   = 0.00064516
    min_size            = 150
    min_g               = 25
    min_h               = 50
    componentUnits      = 'CENTIMETERS'
    pantItemCode        = 'REP'

    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'B [mm]:', 'C [mm]:', 'D [mm]:', 'E [mm]:', 'H [mm]:', 'L [mm]:', 'G [mm]:', 'G1 [mm]:']
      results = UI.inputbox(prompts, defaults, 'Enter Values for Pants')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input for variables
      input_defaults = [pant_a, pant_b, pant_c, pant_d, pant_e, pant_h, pant_l, pant_g, pant_g1]
      user_input = get_user_input(input_defaults)

      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 9
        filter_message = true
        return
      end

      # Extract values from user input
      pant_a, pant_b, pant_c, pant_d, pant_e, pant_h, pant_l, pant_g, pant_g1 = user_input[0..8].map { |value| value }

      # Check if variables are valid
      # a, b, c, d >= 150 mm,
      # h > 50 mm
      # L > 200 mm, 
      # e, g, g1 >=25 mm
      if  pant_a < min_size && pant_b < min_size && pant_c < min_size && pant_d < min_size && 
          pant_h < min_h && pant_l < min_size && pant_g < min_g && pant_g1 < min_g && pant_e < min_g
        msg = 
        'Invalid values detected!!! 
        
        Check the following conditions:
        A, B, C, D, L >= '  + min_size.to_s.gsub(/\s+/, "") + 
        'H >= '             + min_g.to_s.gsub(/\s+/, "") +
        'E, G, G1 >= '      + min_g.to_s.gsub(/\s+/, "")
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Create a new group & Get the group entities
      group = model.active_entities.add_group
      group_entities = group.entities

      # Make values available as length
      pant_a    = pant_a.mm
      pant_b    = pant_b.mm
      pant_c    = pant_c.mm
      pant_d    = pant_d.mm
      pant_e    = pant_e.mm
      pant_h    = pant_h.mm
      pant_l    = pant_l.mm
      pant_g    = pant_g.mm
      pant_g1   = pant_g1.mm

      # Create the geometry inside the group
      point1  = Geom::Point3d.new(pant_a, 0, 0)
      point2  = Geom::Point3d.new(point1.x, pant_g, 0)
      point3  = Geom::Point3d.new(point1.x + (pant_c + pant_d + pant_e - pant_a) / 2, pant_l - pant_g1, 0)
      point4  = Geom::Point3d.new(point3.x, pant_l, 0)
      point5  = Geom::Point3d.new(point4.x - pant_d, pant_l, 0)
      point6  = Geom::Point3d.new(point5.x, pant_l - pant_g1, 0)
      point7  = Geom::Point3d.new(point6.x - pant_e / 2, point6.y - pant_h, 0)
      point8  = Geom::Point3d.new(point6.x - pant_e, pant_l - pant_g1, 0)
      point9  = Geom::Point3d.new(point8.x, pant_l, 0)
      point10 = Geom::Point3d.new(point9.x - pant_c, pant_l, 0)
      point11 = Geom::Point3d.new(point10.x, pant_l - pant_g1, 0)
      point12 = Geom::Point3d.new(0, pant_g, 0)
      point13 = Geom::Point3d.new(point1.x, point1.y, pant_b)
      point14 = Geom::Point3d.new(point5.x, point5.y, pant_b)
      point15 = Geom::Point3d.new(point10.x, point10.y, pant_b)
      face1   = group_entities.add_face ORIGIN, point1, point2, point3, point4, point5, point6, point7, point8, point9, point10, point11, point12, ORIGIN
      face1.pushpull(- pant_b)

      # Identify the 3 faces to delete and calculate the pant area
      # face1 is defined by ORIGIN, point1, point13
      # face2 is defined by point4, point5, point14
      # face3 is defined by point9, point10, point15
      face1, face2, face3 = nil, nil, nil

      group.entities.grep(Sketchup::Face).each do |face|
        if  face.classify_point(ORIGIN)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point1)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point13)  == Sketchup::Face::PointOnVertex && 
          face1 = face
        end

        if  face.classify_point(point4)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point5)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point14)  == Sketchup::Face::PointOnVertex && 
          face2 = face
        end

        if  face.classify_point(point9)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point10)  == Sketchup::Face::PointOnVertex && 
            face.classify_point(point15)  == Sketchup::Face::PointOnVertex && 
          face3 = face
        end
        area_square_inches += face.area
      end

      # Deduct the faces to delete from area, transform in m2 and delete the faces
      area_square_inches = area_square_inches - face1.area - face2.area - face3.area
      pant_area = area_square_inches * conversion_factor
      face1.erase!
      face2.erase!
      face3.erase!

      # Set the name of the group, example: -RP A_500 B_300 C_300 D_350 E_100 H_100 G_25 G1_25 L_400 Area_0.8201
      pant_a_str       = pant_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_b_str       = pant_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_c_str       = pant_c.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_d_str       = pant_d.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_e_str       = pant_e.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_h_str       = pant_h.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_g_str       = pant_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_g1_str      = pant_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_l_str       = pant_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      pant_area_str    = pant_area.round(4).to_s

      pant_group_name  = "-" + pantItemCode + " A_"  + pant_a_str  + 
                        " B_"     + pant_b_str  + 
                        " C_"     + pant_c_str  + 
                        " D_"     + pant_d_str  + 
                        " E_"     + pant_e_str  + 
                        " H_"     + pant_h_str  + 
                        " G_"     + pant_g_str  + 
                        " G1_"    + pant_g1_str + 
                        " L_"     + pant_l_str  + 
                        " Area_"  + pant_area_str

      # Check if the component is present in the model
      existing_component = model.definitions[pant_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[pant_group_name], trans)
          number = Sketchup.active_model.definitions[pant_group_name].count_instances
          component_new_instance.name = number.to_s
      else # Add component and it's attributes

        component_instance = group.to_component
        comp_def = component_instance.definition
        comp_def.name = pant_group_name

        AttrCreate.CreateGeneralAttributes(comp_def, componentUnits, pantItemCode)

        AttrCreate.CreateDimensionAttributes(comp_def, 'a', pant_a_str, 'STRING', 'A', 'A[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'b', pant_b_str, 'STRING', 'B', 'B[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'c', pant_c_str, 'STRING', 'C', 'C[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'd', pant_d_str, 'STRING', 'D', 'D[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'e', pant_e_str, 'STRING', 'E', 'E[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'h', pant_h_str, 'STRING', 'H', 'H[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g', pant_g_str, 'STRING', 'G', 'G[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g1', pant_g1_str, 'STRING', 'G1', 'G1[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'l', pant_l_str, 'STRING', 'L', 'L[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'uarea', pant_area_str, 'STRING', 'Area', 'Area[m2]', 'VIEW')
        AttrCreate.CreateFormulaAttributes(comp_def, 'uairspeed', 'STRING', 'uAirSpeed', 'Air Speed[m/s]', 'VIEW', 'uairflow/3600/(a*b/1000000)')

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
# Pants.run