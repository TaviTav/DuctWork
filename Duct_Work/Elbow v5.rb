module Elbow
  def self.run
    # Rectangular elbow
    # Version 5
    # Bugs: R=0
    # To do: TEST !!!!
    # To Do: improve a little, you have example in Step v2.rb it doesn't matter if a = a1 or a <> a1

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    elbow_a         = 300.mm
    elbow_a1        = 250.mm
    elbow_b         = 300.mm
    elbow_g         = 50.mm
    elbow_g1        = 25.mm
    elbow_r         = 100.mm
    start_a         = 0.0
    elbow_angle     = 90.degrees
    elbow_area      = 0.0
    filter_message      = false
    conversion_factor   = 0.00064516
    area_square_inches  = 0.0

    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A (mm):', 'A1 (mm):', 'B (mm):', 'G (mm):', 'G1 (mm):', 'R (mm):', 'Elbow Angle <° (degrees):']
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
        return
      end

      # Extract values from user input
      elbow_a, elbow_a1, elbow_b, elbow_g, elbow_g1, elbow_r = user_input[0..5].map { |value| value.inch }
      elbow_angle = user_input[6].degrees

      # Check if variables are valid
      # A, A1, B >= 100 mm, 
      # A >= A1,
      # G, G1 >= 25 mm,
      # R >= 0 mm,
      # 0° <= Elbow angle <= 90°
      if  elbow_a < 100.mm && elbow_a1 < 100.mm && elbow_b < 100.mm && 
          elbow_a >= elbow_a1 &&
          elbow_g < 25.mm && elbow_g1 < 25.mm && 
          elbow_r < 0 && 
          elbow_angle < 0.degrees && elbow_angle > 90.degrees
            
        msg = 'Invalid values detected!!! 
        
        Check the following conditions:
        A, A1, B >= 100 mm, 
        A >= A1,
        G, G1 >= 25 mm,
        R >= 0 mm,
        0° <= Elbow angle <= 90°'
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Create a new group
      group = model.active_entities.add_group
      
      # Get the group entities
      group_entities = group.entities

      # Draw Geometry
      p01 = Geom::Point3d.new(0, 0, 0)
      p02 = Geom::Point3d.new(0, elbow_g1, 0)
      p03 = Geom::Point3d.new(elbow_a1, elbow_g1, 0)
      p04 = Geom::Point3d.new(elbow_a1, 0, 0)

      p06 = Geom::Point3d.new(elbow_a, 0, 0)
      p07 = Geom::Point3d.new(elbow_a, -elbow_g, 0)
      p08 = Geom::Point3d.new(0, -elbow_g, 0)
      center_point_arc1 = Geom::Point3d.new(-elbow_r, 0, 0)

      # Create, rotate and update the points of edges2
      edges2    = group_entities.add_edges(p01, p02, p03, p04)
      rotation  = Geom::Transformation.rotation(center_point_arc1, Z_AXIS, elbow_angle)
      group_entities.transform_entities(rotation, edges2)
      p01 = edges2[0].vertices.map(&:position).first
      p02 = edges2[1].vertices.map(&:position).first
      p03 = edges2[1].vertices.map(&:position).last
      p04 = edges2[2].vertices.map(&:position).last

      # Create edges1 and arc1
      edges1      = group_entities.add_edges(p06, p07, p08, ORIGIN)
      arc1        = group_entities.add_arc(center_point_arc1, X_AXIS, Z_AXIS, elbow_r, start_a, elbow_angle)
      arc1_points = arc1[0].curve.vertices.map(&:position)

      if elbow_a == elbow_a1
        arc2      = group_entities.add_arc(center_point_arc1, X_AXIS, Z_AXIS, elbow_r + elbow_a, start_a, elbow_angle)
        allEdges  = edges1 + arc1 + edges2 + arc2 
      else # Crazy Crazy Crazy
        # Create vector v1, v2 and find the intersection point
        v1         = Geom::Vector3d.new(Math.cos(elbow_angle - 90.degrees), Math.sin(elbow_angle - 90.degrees), 0)
        v2         = Geom::Vector3d.new(0, 1, 0) # parallel on Y axis
        tempLine1  = [p04, v1]
        tempLine2  = [p06, v2]
        pi1        = Geom.intersect_line_line(tempLine1, tempLine2)
        # Check if the geometry is valid pi1.y > 0
        if pi1.y < 0
          msg =  'Invalid geometry!!! 
          
                  You have following options:
                  1. Increase A1 but keep it lower or equal with A
                  2. Increase the elbow angle
                  Intersection point must be > 0: 
                  Current value: ' + pi1.y.round(4).to_s + '
                  Some geometry is created, check the origin.'
          UI.messagebox(msg)
          filter_message = true
          return
        else
          v3 = Geom::Vector3d.new(Math.cos(elbow_angle / 2), Math.sin(elbow_angle / 2), 0)
          v4 = Geom::Vector3d.new(1, 0, 0) # parallel on X axis
          tempLine3         = [pi1, v3]
          tempLine4         = [ORIGIN, v4]
          center_point_arc2 = Geom.intersect_line_line(tempLine3, tempLine4)
          arc2Radius        = p06.x - center_point_arc2.x
          arc2              = group_entities.add_arc(center_point_arc2, X_AXIS, Z_AXIS, arc2Radius, start_a, elbow_angle)
          arc2_points       = arc2[0].curve.vertices.map(&:position)
          p05               = arc2_points.last
          edges3            = group_entities.add_edges(p04, p05)
          allEdges          = edges1 + arc1 + edges2 + edges3 + arc2 
        end # geometry valid

      end # end for A = A1 or A <> A1 situations

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
      # Move the entire group to origin
      v5 = Geom::Vector3d.new(0, elbow_g, 0) # parallel on X axis
      translation = Geom::Transformation.translation(v5)
      group_entities.transform_entities(translation, group_entities.to_a)

      # Set the name of the group, example: -CR <°_90 R_100 A_300 A1_300 B_300 G_25 G1_25 Area_0.5279
      elbow_r_str       = elbow_r.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_a_str       = elbow_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_a1_str      = elbow_a1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_b_str       = elbow_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_g_str       = elbow_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_g1_str      = elbow_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      elbow_area_str    = elbow_area.round(4).to_s

      elbow_group_name  = "-CR <°_" + (elbow_angle * 180 / Math::PI).round.to_s + 
                          " R_"   + elbow_r_str   + 
                          " A_"   + elbow_a_str   + 
                          " A1_"  + elbow_a1_str  + 
                          " B_"   + elbow_b_str   + 
                          " G_"   + elbow_g_str   + 
                          " G1_"  + elbow_g1_str  + 
                          " Area_"+ elbow_area_str

      existing_component = model.definitions[elbow_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[elbow_group_name], trans)
          number = Sketchup.active_model.definitions[elbow_group_name].count_instances
          component_new_instance.name = number.to_s
      else
        # group.name = elbow_group_name
        component_instance = group.to_component
        definition = component_instance.definition
        definition.name = elbow_group_name
        component_instance.name = '1'
      end

    rescue => e
      # filter some common errors and do not message the user
      if !filter_message
        UI.messagebox("Grrrr some unknown error occurred: #{e.message}") 
      else
        # nothing here yet
      end
    end # End Main Code

  end # def self.run
end # Module

### Test!!! Don't forget to comment this line !!! ###
# Elbow.run