# Rectangular elbow
# Version Beta v8
# Bugs:
# To do:
# To do: MORE TESTING IS REQUIRED !!!!

# v8 changes:
# Adding attributes to the component
# Small code improvements

require_relative 'AttrCreate.rb'

module Elbow
  def self.run

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    elbow_a         = 300
    elbow_a1        = 250
    elbow_b         = 300
    elbow_g         = 25
    elbow_g1        = 25
    elbow_r         = 100
    start_a         = 0.0
    elbow_angle     = 90.degrees
    elbow_area      = 0.0
    elbow_inverted  = false
    area_square_inches  = 0.0
    filter_message      = false

    # Constants
    conversion_factor   = 0.00064516
    min_size        = 150
    min_g           = 25
    componentUnits      = 'CENTIMETERS'
    elbowItemCode        = 'REL'

    # Create a function for custom dialog box to retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'A1 [mm]:', 'B [mm]:', 'G [mm]:', 'G1 [mm]:', 'R [mm]:', 'Elbow Angle <° (degrees):']
      results = UI.inputbox(prompts, defaults, 'Enter Values for Elbow')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input for variables
      input_defaults = [elbow_a, elbow_a1, elbow_b, elbow_g, elbow_g1, elbow_r, elbow_angle.radians.round(0)]
      user_input = get_user_input(input_defaults)
      
      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 7
        filter_message = true
        exit(0)
      end

      # Extract values from user input
      elbow_a, elbow_a1, elbow_b, elbow_g, elbow_g1, elbow_r = user_input[0..5].map { |value| value }
      elbow_angle = user_input[6].degrees

      # Check if the elbow starts with smaller side on origin and switch values between A and A1, G and G1
      if elbow_a < elbow_a1
        elbow_a, elbow_a1 = elbow_a1, elbow_a
        elbow_g, elbow_g1 = elbow_g1, elbow_g
        elbow_inverted    = true
      end

      # Check if variables are valid
      # A, A1, B >= 100 mm (min_size). Smaller size elbows are dificult to make (?)
      # G, G1 >= 25 mm (min_g). Space for 20 or 30mm flanges
      # R >= 0 mm.
      # 0° <= Elbow angle <= 90°. 
      if  elbow_a < min_size && elbow_a1 < min_size && elbow_b < min_size &&
          elbow_g < min_g && elbow_g1 < min_g && 
          elbow_r < 0 && 
          elbow_angle < 0.degrees && elbow_angle > 90.degrees

        msg = 
        'Invalid values detected!!! 
        
        Check the following conditions:
        A, A1, B >= ' + min_size.to_s.gsub(/\s+/, "") + '
        G, G1 >= ' + min_g.to_s.gsub(/\s+/, "") + '
        R >= 0 mm,
        0° <= Elbow Angle <= 90°'
        UI.messagebox(msg)
        # filter_message = true
        exit(0)
      end

      # Create a new group & Get the group entities
      group = model.active_entities.add_group
      group_entities = group.entities

      # Make values available as length
      elbow_a   = elbow_a.mm
      elbow_a1  = elbow_a1.mm
      elbow_b   = elbow_b.mm
      elbow_g   = elbow_g.mm
      elbow_g1  = elbow_g1.mm
      elbow_r   = elbow_r.mm

      # Draw geometry
      # Create relevant vectors 
      v1 = Geom::Vector3d.new(  Math.cos(elbow_angle - 90.degrees), 
                                Math.sin(elbow_angle - 90.degrees), 0)
      v2 = Geom::Vector3d.new(0, 1, 0) # parallel on Y axis
      v3 = Geom::Vector3d.new(Math.cos(elbow_angle / 2), Math.sin(elbow_angle / 2), 0)
      v4 = Geom::Vector3d.new(1, 0, 0) # parallel on X axis
      # v5 = Geom::Vector3d.new(Math.cos(elbow_angle), Math.sin(elbow_angle), 0)
      
      # Draw arc1 if R > 0 and define p01
      if elbow_r > 0
        center_point_arc1 = Geom::Point3d.new(-elbow_r, 0, 0)
        arc1        = group_entities.add_arc(center_point_arc1, X_AXIS, Z_AXIS, elbow_r, start_a, elbow_angle)
        arc1_points = arc1[0].curve.vertices.map(&:position)
        p01         = arc1_points.last
      else
        p01 = ORIGIN
      end

      # Define p02 as offset with G1 distance of p01 with elbow_angle + 90°
      # Define p03 as offset with A1 distance of p02 with elbow_angle
      # Define p04 as offset with A1 distance of p01 with elbow_angle
      # Define p06, p07, p08
      p02 = Geom::Point3d.new(  p01.x + Math.cos(elbow_angle + 90.degrees) * elbow_g1, 
                                p01.y + Math.sin(elbow_angle + 90.degrees) * elbow_g1, 0)
      p03 = Geom::Point3d.new(  p02.x + Math.cos(elbow_angle) * elbow_a1, 
                                p02.y + Math.sin(elbow_angle) * elbow_a1, 0)
      p04 = Geom::Point3d.new(  p01.x + Math.cos(elbow_angle) * elbow_a1, 
                                p01.y + Math.sin(elbow_angle) * elbow_a1, 0)
      p06 = Geom::Point3d.new(elbow_a, 0, 0)
      p07 = Geom::Point3d.new(elbow_a, -elbow_g, 0)
      p08 = Geom::Point3d.new(0, -elbow_g, 0)

      # Find pi1 as intersection of p04+v1 and p06+v2
      tempLine1  = [p04, v1]
      tempLine2  = [p06, v2]
      pi1        = Geom.intersect_line_line(tempLine1, tempLine2)

      # Check if the geometry is valid pi1.y > 0
      if pi1.y < 0
        msg =  
        'Invalid geometry!!! 
        
        You have following options:
        1. Increase the value of the smaller side, 
        closer to the bigger side
        2. Increase the elbow angle
        Intersection point must be > 0: 
        Current value: ' + pi1.y.round(4).to_s + '
        Some geometry is created, check the origin.'
        UI.messagebox(msg)
        # filter_message = true
        exit(0)
      end

      # Find center_point_arc2 as intersection of pi1+v3 and ORIGIN+v4; Find arc2 radius
      # Draw arc2 and find p05 as last point of arc2
      tempLine1         = [pi1, v3]
      tempLine2         = [ORIGIN, v4]
      center_point_arc2 = Geom.intersect_line_line(tempLine1, tempLine2)
      arc2Radius        = p06.x - center_point_arc2.x
      arc2              = group_entities.add_arc(center_point_arc2, X_AXIS, Z_AXIS, arc2Radius, start_a, elbow_angle)
      arc2_points       = arc2[0].curve.vertices.map(&:position)
      p05               = arc2_points.last

      # Draw all posible edges
      edges1  = group_entities.add_edges(p06, p07, p08, ORIGIN)
      edges2  = group_entities.add_edges(p01, p02, p03, p04)
      edges3  = group_entities.add_edges(p04, p05)

      # Find all edges non-nil with length > 0
      allEdges = []
      group.entities.each do |entity|
        # Check if the entity is an edge or arc and not nil
        if (entity.is_a?(Sketchup::Edge) || entity.is_a?(Sketchup::Arc)) && !entity.nil?
          # Check if the edge has a non-zero length
          if entity.length > 0
            # Add the edge or arc to the allEdges array
            allEdges << entity
          end
        end
      end

      face = group_entities.add_face(allEdges)
      face.pushpull(- elbow_b)

      # Identify the 2 faces we want to delete
      # face1 is defined by p02, p03 and p02 elevated with B
      # face2 is defined by p07, p08 and p07 elevated with B
      face1, face2 = nil, nil
      p02Elevated = Geom::Point3d.new(p02.x, p02.y, elbow_b)
      p07Elevated = Geom::Point3d.new(p07.x, p07.y, elbow_b)

      group.entities.grep(Sketchup::Face).each do |face|
        if  face.classify_point(p02)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p03)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p02Elevated)  == Sketchup::Face::PointOnVertex
          face1 = face
        end

        if  face.classify_point(p07)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p08)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p07Elevated)  == Sketchup::Face::PointOnVertex
          face2 = face
        end
        area_square_inches += face.area
      end

      # Deduct the faces from total area, transform in m2 and delete the faces
      area_square_inches  = area_square_inches - face1.area - face2.area
      elbow_area          = area_square_inches * conversion_factor
      face1.erase!
      face2.erase!

      # Make p08 the origin of the component
      # Bigger side on X axis
      v5 = Geom::Vector3d.new(0, elbow_g, 0) # parallel on X axis
      tr = Geom::Transformation.translation(v5)
      group_entities.transform_entities(tr, group_entities.to_a)

      # If the user wants A < A1 we make p02 the origin of the component
      # This is useful for ramifications
      # Smaller side on X axis
      if elbow_inverted
        # move p02 to origin, flip along red and rotate with 180 + elbow_angle
        v6 = Geom::Vector3d.new(0, 0, 0) - p02.vector_to(p08)
        tr = Geom::Transformation.translation(v6)
        # group.transform!(translation.invert!)
        group_entities.transform_entities(tr.invert!, group_entities.to_a)

        fl = Geom::Transformation.scaling([0,0,0], -1, 1, 1)
        group_entities.transform_entities(fl, group_entities.to_a)

        ro = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 180.degrees + elbow_angle)
        group_entities.transform_entities(ro, group_entities.to_a)

        elbow_a, elbow_a1 = elbow_a1, elbow_a
        elbow_g, elbow_g1 = elbow_g1, elbow_g
      end

      # Set the name of the group, example: -REL <°_90 R_100 A_300 A1_250 B_300 G_25 G1_25 Area_0.4937
      elbow_r_str       = elbow_r.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_a_str       = elbow_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_a1_str      = elbow_a1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_b_str       = elbow_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_g_str       = elbow_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_g1_str      = elbow_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_area_str    = elbow_area.round(4).to_s
      elbow_angle_str   = (elbow_angle * 180 / Math::PI).round.to_s

      elbow_group_name  = "-" + elbowItemCode + " Angle_" + elbow_angle_str + '°' +
                          " R_"   + elbow_r_str   + 
                          " A_"   + elbow_a_str   + 
                          " A1_"  + elbow_a1_str  + 
                          " B_"   + elbow_b_str   + 
                          " G_"   + elbow_g_str   + 
                          " G1_"  + elbow_g1_str  + 
                          " Area_"+ elbow_area_str

      # Check if the component is present in the model
      existing_component = model.definitions[elbow_group_name]
      if existing_component 
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[elbow_group_name], trans)
          number = Sketchup.active_model.definitions[elbow_group_name].count_instances
          component_new_instance.name = number.to_s
      else # Add component and it's attributes
        component_instance = group.to_component
        comp_def = component_instance.definition
        comp_def.name = elbow_group_name

        AttrCreate.CreateGeneralAttributes(comp_def, componentUnits, elbowItemCode)

        AttrCreate.CreateDimensionAttributes(comp_def, 'a', elbow_a_str, 'STRING', 'A', 'A[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'a1', elbow_a1_str, 'STRING', 'A1', 'A1[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'b', elbow_b_str, 'STRING', 'B', 'B[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g', elbow_g_str, 'STRING', 'G', 'G[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g1', elbow_g1_str, 'STRING', 'G1', 'G1[mm]', 'VIEW')        
        AttrCreate.CreateDimensionAttributes(comp_def, 'r', elbow_r_str, 'STRING', 'R', 'R[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'angle', elbow_angle_str, 'STRING', 'Angle', 'Angle[°]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'uarea', elbow_area_str, 'STRING', 'Area', 'Area[m2]', 'VIEW')

        AttrCreate.CreateFormulaAttributes(comp_def, 'uairspeed', 'STRING', 'uAirSpeed', 'Air Speed[m/s]', 'VIEW', 'uairflow/3600/(smallest(a,a1)*b/1000000)')

        dcs = $dc_observers.get_latest_class
        dcs.redraw_with_undo(component_instance)
      end

    rescue => e
      UI.messagebox("Grrrr some unknown error occurred: #{e.message}")
    end # End Main Code

  end # def self.run
end # Module

### Test!!! Don't forget to comment this line !!! ###
# Elbow.run