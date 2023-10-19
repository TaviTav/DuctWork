# Rectangular step offset
# Version Beta 5
# Bugs:
# To do: MORE TESTING IS REQUIRED !!!!
# To do: 

# v5 changes:
# Adding attributes to the component
# Small code improvements
# Dimension L on picture in documentation

require_relative 'AttrCreate.rb'

module Step
  def self.run

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    step_a          = 500
    step_a1         = 400
    step_b          = 300
    step_f          = 250
    step_g          = 25
    step_g1         = 25
    step_l          = 0
    step_r          = 100
    start_a         = 0.0
    step_angle      = 30.degrees
    step_area       = 0.0
    step_inverted   = false
    area_square_inches  = 0.0
    filter_message      = false

    # Constants
    conversion_factor   = 0.00064516
    min_size            = 150
    min_g               = 25
    min_f               = 50
    componentUnits      = 'CENTIMETERS'
    stepItemCode        = 'RSO'    


    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'A1 [mm]:', 'B [mm]:', 'F [mm]:', 'G [mm]:', 'G1 [mm]:', 'R [mm]:', '<° (degrees):']
      results = UI.inputbox(prompts, defaults, 'Enter Values for Step/Offset')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input for variables
      input_defaults = [step_a, step_a1, step_b, step_f, step_g, step_g1, step_r, step_angle.radians.round(0)]
      user_input = get_user_input(input_defaults)

      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 8
        filter_message = true
        return
      end

      # Extract values from user input
      step_a, step_a1, step_b, step_f, step_g, step_g1, step_r = user_input[0..6].map { |value| value }
      step_angle = user_input[7].degrees

      # Check if the step starts with smaller side on origin and switch values between A and A1, G and G1
      if step_a < step_a1
        step_a, step_a1 = step_a1, step_a
        step_g, step_g1 = step_g1, step_g
        step_f = step_f - step_a + step_a1 # make sure F dimension stays on left side of the origin
        step_inverted   = true
      end

      # Check if variables are valid
      # A, A1, B > 100 mm
      # F >= 50 mm
      # G, G1 >= 25 mm 
      # R >= 0 mm 
      # 0 < Angle <= 90°
      if step_a < min_size && step_a1 < min_size && step_b < min_size && 
        step_f < min_f && step_g < min_g && step_g1 < min_g && step_r < 0 && 
        step_angle < 0.degrees && step_angle > 90.degrees
        msg = 
        'A, A1, B ' + min_size.to_s.gsub(/\s+/, "") +
        'F > ' + min_f.to_s.gsub(/\s+/, "") +
        'G, G1 >= ' + min_g.to_s.gsub(/\s+/, "") +
        'R >= 0 mm 
        0 < Angle <= 90°'
        UI.messagebox(msg)
        filter_message = true
        return
      end
      
      # Create a new group & Get the group entities
      group = model.active_entities.add_group
      group_entities = group.entities

      # Make values available as length
      step_a    = step_a.mm
      step_a1   = step_a1.mm
      step_b    = step_b.mm
      step_f    = step_f.mm
      step_g    = step_g.mm
      step_g1   = step_g1.mm
      step_r    = step_r.mm

      # Draw geometry
      # Create relevant vectors 
      v1 = Geom::Vector3d.new(  Math.cos(step_angle - 90.degrees), 
                                Math.sin(step_angle - 90.degrees), 0)
      v2 = Geom::Vector3d.new(0, 1, 0) # parallel on Y axis
      v3 = Geom::Vector3d.new(Math.cos(step_angle / 2), Math.sin(step_angle / 2), 0)
      v4 = Geom::Vector3d.new(1, 0, 0) # parallel on X axis
      v5 = Geom::Vector3d.new(Math.cos(step_angle), Math.sin(step_angle), 0)

      # Draw arc1 and define p01
      if step_r > 0.mm
        center_point_arc1 = Geom::Point3d.new(-step_r, 0, 0)
        arc1 = group_entities.add_arc(center_point_arc1, X_AXIS, Z_AXIS, step_r, start_a, step_angle)
        arc1_points = arc1[0].curve.vertices.map(&:position)
        p01 = arc1_points.last
      else
        p01 = ORIGIN
      end

      # Define p09 as offset of p01 with distance A - (A - A1)/2, p11, p12, p13 and draw edges1
      p09 = Geom::Point3d.new(  p01.x + Math.cos(step_angle) * (step_a - (step_a - step_a1) / 2), 
                                p01.y + Math.sin(step_angle) * (step_a - (step_a - step_a1) / 2), 0)
      p11 = Geom::Point3d.new(step_a, 0, 0)
      p12 = Geom::Point3d.new(step_a, -step_g, 0)
      p13 = Geom::Point3d.new(0, -step_g, 0)
      edges1 = group_entities.add_edges(ORIGIN, p13, p12, p11)

      # Find pi1 as intersection of p09+v1 & p11+v2, error if pi1 < 0
      tempLine1  = [p09, v1]
      tempLine2  = [p11, v2]
      pi1        = Geom.intersect_line_line(tempLine1, tempLine2)
      if pi1.y < 0
        msg =  'Invalid geometry!!! 
        
                You have following options:
                1. Increase A1 but keep it lower or equal with A
                2. Increase the step angle
                Intersection point must be > 0: 
                Current value: ' + pi1.y.round(4).to_s + '
                Some geometry is created, check the origin.'
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Find center_point_arc2 as intersection of pi1+v3 and ORIGIN+v4; Find arc2 radius
      # Draw arc2 and find p10 as last point of arc2
      tempLine1  = [pi1, v3]
      tempLine2  = [ORIGIN, v4]
      center_point_arc2 = Geom.intersect_line_line(tempLine1, tempLine2)
      arc2Radius        = p11.x - center_point_arc2.x
      arc2              = group_entities.add_arc(center_point_arc2, X_AXIS, Z_AXIS, arc2Radius, start_a, step_angle)
      arc2_points       = arc2[0].curve.vertices.map(&:position)
      p10               = arc2_points.last

      # Find center_point_arc3.x and pi3 as offset of p09 with distance R
      # Find center_point_arc3 as intersection of center_point_arc3.x +v2 and pi3+v1
      c3x = Geom::Point3d.new(- step_f + step_a1 + step_r, 0, 0)
      pi3 = Geom::Point3d.new(  p09.x + Math.cos(step_angle) * step_r, p09.y + Math.sin(step_angle) * step_r, 0)
      tempLine1  = [c3x, v2]
      tempLine2  = [pi3, v1]
      center_point_arc3 = Geom.intersect_line_line(tempLine1, tempLine2)

      # Don't draw it if we don't need it, find p08 as last point on arc3
      if step_r > 0.mm
        arc3 = group_entities.add_arc(center_point_arc3, X_AXIS, Z_AXIS, step_r, start_a + 180.degrees, step_angle + 180.degrees)       
        arc3_points = arc3[0].curve.vertices.map(&:position)
        p08 = arc3_points.last
      else
        p08 = center_point_arc3
      end

      # Find p04, p05, p06, p07, p08
      p04 = Geom::Point3d.new(center_point_arc3.x - step_a1 - step_r, center_point_arc3.y, 0)
      p05 = Geom::Point3d.new(p04.x, p04.y + step_g1, 0)
      p06 = Geom::Point3d.new(p05.x + step_a1, p05.y, 0)
      p07 = Geom::Point3d.new(center_point_arc3.x - step_r, center_point_arc3.y, 0)

      # Extra condition to avoid invalid geometry
      if p08.x > p09.x 
        msg =  'Invalid geometry!!! 
        
                You have following options:
                1. Increase F
                2. Decrease the step angle
                Value must be > 0: 
                Current value: ' + (p09.x - p08.x).to_s + '
                Some geometry is created, check the origin.'
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Find pi2 as intersection of p01+v1 and p04+v2
      tempLine1  = [p01, v1]
      tempLine2  = [p04, v2]
      pi2 = Geom.intersect_line_line(tempLine1, tempLine2)

      # Find center_point_arc4 as intersection of pi2+v3 and center_point_arc3+v5
      tempLine1  = [pi2, v3]
      tempLine2  = [center_point_arc3, v5]
      center_point_arc4 = Geom.intersect_line_line(tempLine1, tempLine2)

      # Find arc4Radius, draw arc4, find p02 as last point on arc4, p03 as first point on arc4
      tempLine1  = [p01, v1]
      arc4Radius = center_point_arc4.distance_to_line(tempLine1)
      arc4 = group_entities.add_arc(center_point_arc4, X_AXIS, Z_AXIS, arc4Radius, start_a + 180.degrees, step_angle + 180.degrees)
      arc4_points = arc4[0].curve.vertices.map(&:position)
      p02 = arc4_points.last
      p03 = arc4_points.first

      # Draw all posible edges
      edges2 = group_entities.add_edges(p01, p02)
      edges3 = group_entities.add_edges(p03, p04)
      edges4 = group_entities.add_edges(p04, p05, p06, p07)
      edges5 = group_entities.add_edges(p08, p09)
      edges6 = group_entities.add_edges(p09, p10) 

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
      face.pushpull(- step_b)

      # Identify the 2 faces we want to delete
      # face1 is defined by p12, p13 and p12 elevated with B
      # face2 is defined by p05, p06 and p05 elevated with B
      face1, face2 = nil, nil
      p12Elevated = Geom::Point3d.new(p12.x, p12.y, step_b)
      p05Elevated = Geom::Point3d.new(p05.x, p05.y, step_b)

      group.entities.grep(Sketchup::Face).each do |face|
        if  face.classify_point(p12)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p13)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p12Elevated)  == Sketchup::Face::PointOnVertex
          face1 = face
        end

        if  face.classify_point(p05)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p06)          == Sketchup::Face::PointOnVertex && 
            face.classify_point(p05Elevated)  == Sketchup::Face::PointOnVertex
          face2 = face
        end
        area_square_inches += face.area
      end

      # Deduct the faces from total area, transform in m2 and delete the faces
      area_square_inches  = area_square_inches - face1.area - face2.area
      step_area          = area_square_inches * conversion_factor
      face1.erase!
      face2.erase!

      # Make p13 the origin of the component
      # Bigger side on X axis
      v6 = Geom::Vector3d.new(0, step_g, 0) # parallel on X axis
      translation = Geom::Transformation.translation(v6)
      group_entities.transform_entities(translation, group_entities.to_a)

      # If the user wants A < A1 we make p05 the origin of the component
      # This is useful for ramifications
      # Smaller side on X axis
      if step_inverted
        # move p06 to origin, flip along red and rotate with 180
        v6 = Geom::Vector3d.new(0, 0, 0) - p06.vector_to(p13)
        tr = Geom::Transformation.translation(v6)
        # group.transform!(translation.invert!)
        group_entities.transform_entities(tr.invert!, group_entities.to_a)

        #fl = Geom::Transformation.scaling([0,0,0], -1, 1, 1)
        #group_entities.transform_entities(fl, group_entities.to_a)

        ro = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 180.degrees)
        group_entities.transform_entities(ro, group_entities.to_a)

        step_a, step_a1 = step_a1, step_a
        step_g, step_g1 = step_g1, step_g
        step_f = (step_f + step_a1 - step_a).inch # make sure F dimension is correct
      end

      # Set the name of the group, example: 
      # -RSO <°_30 R_100 A_500 A1_400 B_300 F_250 G_25 G1_25 L_711 Area_1.2239
      step_l            = p05.y.round(0)
      step_r_str        = step_r.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      step_a_str        = step_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      step_a1_str       = step_a1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      step_b_str        = step_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      step_f_str        = step_f.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      step_g_str        = step_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      step_g1_str       = step_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      step_l_str        = step_l.inch.to_s.gsub(/\s+/, "").gsub(/mm/, "").gsub(/~/, "")
      step_area_str     = step_area.round(4).to_s
      step_angle_str    = (step_angle * 180 / Math::PI).round.to_s

      step_group_name   = '-' + stepItemCode + ' Angle_' + step_angle_str + '°'+ 
                          ' R_'   + step_r_str  + 
                          ' A_'   + step_a_str  + 
                          ' A1_'  + step_a1_str +
                          ' B_'   + step_b_str  + 
                          ' F_'   + step_f_str  + 
                          ' G_'   + step_g_str  + 
                          ' G1_'  + step_g1_str +
                          ' L_'   + step_l_str  +
                          ' Area_' + step_area_str

      # Check if the component is present in the model
      existing_component = model.definitions[step_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component 
          is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[step_group_name], trans)
          number = Sketchup.active_model.definitions[step_group_name].count_instances
          component_new_instance.name = number.to_s
      else # Add component and it's attributes
        component_instance = group.to_component
        comp_def = component_instance.definition
        comp_def.name = step_group_name

        AttrCreate.CreateGeneralAttributes(comp_def, componentUnits, stepItemCode)

        AttrCreate.CreateDimensionAttributes(comp_def, 'a', step_a_str, 'STRING', 'A', 'A[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'a1', step_a1_str, 'STRING', 'A1', 'A1[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'b', step_b_str, 'STRING', 'B', 'B[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'f', step_f_str, 'STRING', 'F', 'F[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g', step_g_str, 'STRING', 'G', 'G[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g1', step_g1_str, 'STRING', 'G1', 'G1[mm]', 'VIEW')   
        AttrCreate.CreateDimensionAttributes(comp_def, 'l', step_l_str, 'STRING', 'L', 'L[mm]', 'VIEW')     
        AttrCreate.CreateDimensionAttributes(comp_def, 'r', step_r_str, 'STRING', 'R', 'R[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'angle', step_angle_str, 'STRING', 'Angle', 'Angle[°]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'uarea', step_area_str, 'STRING', 'Area', 'Area[m2]', 'VIEW')

        AttrCreate.CreateFormulaAttributes(comp_def, 'uairspeed', 'STRING', 'uAirSpeed', 'Air Speed[m/s]', 'VIEW', 'uairflow/3600/(smallest(a,a1)*b/1000000)')

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
    end

  end # def self.run
end # Module

### Test!!! Don't forget to comment this line !!! ###
# Step.run