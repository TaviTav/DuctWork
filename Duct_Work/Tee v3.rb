module Tee
  def self.run
    # Rectangular tee
    # Version Beta 3
    # Bugs: G, G1 values breaks the tee
    # To do:

    # v3 changes:
    # Removed mm from dialog box

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    tee_a     = 300
    tee_b     = 300
    tee_c     = 300
    tee_g     = 25
    tee_g1    = 25
    tee_r     = 100
    tee_l     = 550
    tee_area  = 0.0
    start_a   = 0.0
    end_a     = 90.degrees
    filter_message      = false
    area_square_inches  = 0.0

    # Constants
    conversion_factor   = 0.00064516
    min_size            = 100
    min_g               = 25

    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'B [mm]:', 'C [mm]:', 'G [mm]:', 'G1 [mm]:', 'R [mm]:']
      results = UI.inputbox(prompts, defaults, 'Enter Values for Tee')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input for variables
      input_defaults = [tee_a, tee_b, tee_c, tee_g, tee_g1, tee_r]
      user_input = get_user_input(input_defaults)

      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 6
        filter_message = true
        return
      end

      # Extract values from user input
      tee_a, tee_b, tee_c, tee_g, tee_g1, tee_r = user_input[0..5].map { |value| value }

      # Check if variables are valid
      # a, b, c > 100 mm, 
      # g, g1 > 25 mm
      # r >= 0
      if tee_a < min_size && tee_b < min_size && tee_c < min_size && 
        tee_g < min_g && tee_g1 < min_g && tee_r < 0
        msg = 
        'Invalid values detected!!! 
        
        Check the following conditions:
        A, B, C > ' + min_size.to_s.gsub(/\s+/, "") + 
        'G, G1 >= ' + min_g.to_s.gsub(/\s+/, "") + 
        'R >= 0'
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Create a new group
      group = model.active_entities.add_group

      # Get the group entities
      group_entities = group.entities
      
      # Find the length of the tee
      tee_l = 2 * tee_r + 2 * tee_g + tee_a
      tee_l = tee_l.mm

      tee_a     = tee_a.mm
      tee_b     = tee_b.mm
      tee_c     = tee_c.mm
      tee_g     = tee_g.mm
      tee_g1    = tee_g1.mm
      tee_r     = tee_r.mm

      # Draw arc1, 2
      center_point_arc1 = Geom::Point3d.new(-tee_r, tee_g1, 0)
      center_point_arc2 = Geom::Point3d.new(-tee_r, tee_g1 + tee_a + 2 * tee_r, 0)
      arc1 = group_entities.add_arc(center_point_arc1, X_AXIS, Z_AXIS, tee_r, start_a, end_a)
      arc2 = group_entities.add_arc(center_point_arc2, X_AXIS, Z_AXIS, tee_r, -end_a, start_a)

      # Define points
      point1  = Geom::Point3d.new(tee_c, 0, 0)
      point2  = Geom::Point3d.new(tee_c, tee_l, 0)
      point3  = Geom::Point3d.new(0, tee_l, 0)
      point4  = Geom::Point3d.new(0, tee_l - tee_g1, 0)
      point5  = Geom::Point3d.new(- tee_r, tee_l - tee_g1 - tee_r, 0)
      point6  = Geom::Point3d.new(- tee_r - tee_g, tee_l - tee_g1 - tee_r, 0)
      point7  = Geom::Point3d.new(- tee_r - tee_g, tee_l - tee_g1 - tee_r - tee_a, 0)
      point8  = Geom::Point3d.new(- tee_r, tee_r + tee_g1, 0)
      point9  = Geom::Point3d.new(0, tee_g1, 0)
      point10 = Geom::Point3d.new(point1.x, point1.y, tee_b)
      point11 = Geom::Point3d.new(point3.x, point3.y, tee_b)
      point12 = Geom::Point3d.new(point7.x, point7.y, tee_b)

      # Draw edges
      edges1_array  = group_entities.add_edges(point9, ORIGIN, point1, point2, point3, point4)
      edges2_array  = group_entities.add_edges(point5, point6, point7, point8)
    
      if tee_r == 0
        edges_array = edges1_array + edges2_array
      else
        edges_array = edges1_array + edges2_array + arc1 + arc2
      end

      # Draw and push pull face
      face    = group_entities.add_face(edges_array)
      face.pushpull(- tee_b)

      # Identify the 3 faces to delete and calculate the tee area
      # face1 is defined by ORIGIN, point1, point10
      # face2 is defined by point2, point3, point11
      # face3 is defined by point6, point7, point12

      face1, face2, face3 = nil, nil, nil

      group.entities.grep(Sketchup::Face).each do |face|
        if  face.classify_point(ORIGIN)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point1)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point10)  == Sketchup::Face::PointOnVertex && 
          face1 = face
        end

        if  face.classify_point(point2)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point3)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point11)  == Sketchup::Face::PointOnVertex && 
          face2 = face
        end

        if  face.classify_point(point6)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point7)   == Sketchup::Face::PointOnVertex && 
            face.classify_point(point12)  == Sketchup::Face::PointOnVertex && 
          face3 = face
        end
        area_square_inches += face.area
      end

      # Deduct the faces to delete from area, transform in m2 and delete the faces
      area_square_inches = area_square_inches - face1.area - face2.area - face3.area
      tee_area = area_square_inches * conversion_factor
      face1.erase!
      face2.erase!
      face3.erase!

      # Set the name of the group, example: -TR R_100 A_300 B_300 C_300 G_25 G1_25 L_550 Area_0.7029
      tee_r_str       = tee_r.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      tee_a_str       = tee_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      tee_b_str       = tee_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      tee_c_str       = tee_c.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      tee_g_str       = tee_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      tee_g1_str      = tee_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      tee_l_str       = tee_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      tee_area_str    = tee_area.round(4).to_s

      tee_group_name  = "-TR R_"  + tee_r_str   +
                          " A_"   + tee_a_str   +
                          " B_"   + tee_b_str   + 
                          " C_"   + tee_c_str   + 
                          " G_"   + tee_g_str   + 
                          " G1_"  + tee_g1_str  + 
                          " L_"   + tee_l_str   + 
                          " Area_" + tee_area_str
        
      existing_component = model.definitions[tee_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[tee_group_name], trans)
          number = Sketchup.active_model.definitions[tee_group_name].count_instances
          component_new_instance.name = number.to_s
      else
        # group.name = elbow_group_name
        component_instance = group.to_component
        definition = component_instance.definition
        definition.name = tee_group_name
        component_instance.name = '1'
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
# Tee.run