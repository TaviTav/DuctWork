# Section Change Concentric or Excentric
# Version Beta 2
# Bugs:
# To do: MORE TESTING IS REQUIRED !!!!

# v2 changes:
# Adding attributes to the component
# Small code improvements
# Bug fixed
require_relative 'AttrCreate.rb'

module SC
  def self.run

    # Get a reference to the current active model
    model = Sketchup.active_model

    # Declare variables (initial values)
    ssc_a     = 400
    ssc_b     = 300
    ssc_d     = 250
    ssc_g     = 25
    ssc_g1    = 25
    ssc_l     = 300
    ssc_area  = 0.0
    ssc_exc   = 1
    ssc_str   = ''
    filter_message      = false
    area_square_inches  = 0.0

    # Constants
    conversion_factor   = 0.00064516
    min_size            = 150
    min_g               = 25
    componentUnits      = 'CENTIMETERS'
    scItemCode          = 'SC'

    # Create a custom dialog box and retrieve user input
    def self.get_user_input(defaults)
      prompts = ['A [mm]:', 'B [mm]:', 'D [mm]:', 'G [mm]:', 'G1 [mm]:', 'L [mm]:', 'Concentric:']
      results = UI.inputbox(prompts, defaults, 'Enter Values for Section Change')
      return results.map(&:to_f) if results
    end

    # Main code
    begin
      # Get user input for variables
      input_defaults = [ssc_a, ssc_b, ssc_d, ssc_g, ssc_g1, ssc_l, ssc_exc]
      user_input = get_user_input(input_defaults)

      # Check if user input is canceled or if the correct number of values were entered
      if user_input.nil? || user_input.size != 7
        filter_message = true
        return
      end

      # Extract values from user input
      ssc_a, ssc_b, ssc_d, ssc_g, ssc_g1, ssc_l, ssc_exc = user_input[0..6].map { |value| value }

      # Check if variables are valid
      # a, b, d > 150 mm, 
      # g, g1 > 25 mm
      # L >= g + g1
      if ssc_a < min_size && ssc_b < min_size && ssc_d < min_size && 
        ssc_g < min_g && ssc_g1 < min_g && ssc_l < ssc_g + ssc_g1
        msg = 
        'Invalid values detected!!! 
        
        Check the following conditions:
        A, B, D > ' + min_size.to_s.gsub(/\s+/, "") + 
        'G, G1 >= ' + min_g.to_s.gsub(/\s+/, "") + 
        'L >= G + G1'
        UI.messagebox(msg)
        filter_message = true
        return
      end

      # Create a new group
      group = model.active_entities.add_group

      # Get the group entities
      group_entities = group.entities

      ssc_a     = ssc_a.mm
      ssc_b     = ssc_b.mm
      ssc_d     = ssc_d.mm
      ssc_g     = ssc_g.mm
      ssc_g1    = ssc_g1.mm
      ssc_l     = ssc_l.mm

      # Calculate circle radius and center point
      circle_radius = ssc_d / 2.0
      circle_center_point = Geom::Point3d.new(circle_radius, circle_radius, 0)

      # Create points for 4 triangles
      p1 = Geom::Point3d.new(ssc_d / 2, 0, 0)
      p2 = Geom::Point3d.new(ssc_d, 0, 0)
      p3 = Geom::Point3d.new(ssc_d, ssc_d / 2, 0)
      p4 = Geom::Point3d.new(ssc_d, ssc_d, 0)
      p5 = Geom::Point3d.new(ssc_d / 2, ssc_d, 0)
      p6 = Geom::Point3d.new(0, ssc_d, 0)
      p7 = Geom::Point3d.new(0, ssc_d / 2, 0)
      p8 = ORIGIN

      # Create points for rectangular side of ssc
      p12 = Geom::Point3d.new(ssc_d, 0, -ssc_g)
      p14 = Geom::Point3d.new(ssc_d, ssc_d, -ssc_g)
      p16 = Geom::Point3d.new(0, ssc_d, -ssc_g)
      p18 = Geom::Point3d.new(0, 0, -ssc_g)

      # Create 4 arcs coresponding the 4 triangles
      arc1 = group_entities.add_arc(circle_center_point, X_AXIS, Z_AXIS, circle_radius, 180.degrees, 270.degrees)
      arc2 = group_entities.add_arc(circle_center_point, X_AXIS, Z_AXIS, circle_radius, 270.degrees, 360.degrees)
      arc3 = group_entities.add_arc(circle_center_point, X_AXIS, Z_AXIS, circle_radius, 0.degrees, 90.degrees)
      arc4 = group_entities.add_arc(circle_center_point, X_AXIS, Z_AXIS, circle_radius, 90.degrees, 180.degrees)

      # Create the edges of the 4 triangles
      edges1 = group_entities.add_edges(p7, ORIGIN, p1)
      edges2 = group_entities.add_edges(p1, p2, p3)
      edges3 = group_entities.add_edges(p3, p4, p5)
      edges4 = group_entities.add_edges(p5, p6, p7)

      # Create the 4 faces between triangles and coresponding arcs
      face1 = group_entities.add_face(edges1 + arc1)
      face2 = group_entities.add_face(edges2 + arc2)
      face3 = group_entities.add_face(edges3 + arc3)
      face4 = group_entities.add_face(edges4 + arc4)

      # Move the arcs up with distance ssc_l - ssc_g1
      v1 = Geom::Vector3d.new(0, 0, ssc_l - ssc_g1 - ssc_g) # Move parallel to Z axis
      tr1 = Geom::Transformation.translation(v1)
      group_entities.transform_entities(tr1, arc1, arc2, arc3, arc4)

      # Create a face out of 4 arcs and push pull it with distance ssc_g1
      circle_face = group_entities.add_face(arc1 + arc2 + arc3 + arc4)
      circle_face.pushpull(-ssc_g1)
      # Erase the new created face. This face is defined by 3 points, p1, p3, p5 with height of ssc_l - ssc_g1

      # Get acces to points of the arcs
      arc1_points = arc1[0].curve.vertices.map(&:position)
      arc2_points = arc2[0].curve.vertices.map(&:position)
      arc3_points = arc3[0].curve.vertices.map(&:position)
      arc4_points = arc4[0].curve.vertices.map(&:position)

      # Create four lateral faces between rectangular and round geometry
      edges5 = group_entities.add_edges(ORIGIN, arc1_points.last, p2, ORIGIN)
      edges6 = group_entities.add_edges(p2, arc2_points.last, p4, p2)
      edges7 = group_entities.add_edges(p4, arc3_points.last, p6, p4)
      edges8 = group_entities.add_edges(p6, arc4_points.last, ORIGIN, p6)
      face5 = group_entities.add_face(edges5)
      face6 = group_entities.add_face(edges6)
      face7 = group_entities.add_face(edges7)
      face8 = group_entities.add_face(edges8)

      # Calculate the translation vectors for the 4 rectangular faces
      ssc_a_dist = (ssc_a - ssc_d) / 2
      v2 = Geom::Vector3d.new(ssc_a_dist, 0, 0) # Move parallel to X axis
      tr2_1 = Geom::Transformation.translation(v2)
      tr2_2 = Geom::Transformation.translation(v2.reverse)

      # Create the two faces on rectangular side of the piece coresponding to A size
      # p2, p4, p14, p12, p2
      # p6, p8, p18, p16, p6
      edges10 = group_entities.add_edges(p2, p4, p14, p12, p2)
      edges12 = group_entities.add_edges(p6, p8, p18, p16, p6)
      face10  = group_entities.add_face(edges10)  # ssc_b
      face12  = group_entities.add_face(edges12)  # ssc_b
      group_entities.transform_entities(tr2_1, face10)
      group_entities.transform_entities(tr2_2, face12)

      # Create the two faces on rectangular side of the piece coresponding to B size
      # p8, p2, p12, p18, p8
      # p4, p6, p16, p14, p4
      p8  = Geom::Point3d.new(p8.x - ssc_a_dist, 0, 0)
      p2  = Geom::Point3d.new(p2.x + ssc_a_dist, 0, 0)
      p18 = Geom::Point3d.new(p8.x, 0, -ssc_g)
      p12 = Geom::Point3d.new(p2.x, 0, -ssc_g)
      p4  = Geom::Point3d.new(p4.x + ssc_a_dist, p4.y, 0)
      p6  = Geom::Point3d.new(p6.x - ssc_a_dist, p6.y, 0)
      p16 = Geom::Point3d.new(p6.x, p6.y, -ssc_g)
      p14 = Geom::Point3d.new(p4.x, p4.y, -ssc_g)

      edges9  = group_entities.add_edges(p8, p2, p12, p18, p8)
      edges11 = group_entities.add_edges(p4, p6, p16, p14, p4)
      face9   = group_entities.add_face(edges9)
      face11  = group_entities.add_face(edges11)

      if ssc_exc == 1
        ssc_str = 'C'
        ssc_b_dist = (ssc_b - ssc_d) / 2
        p20 = Geom::Point3d.new(0, -ssc_b_dist, ssc_g)
        v3 = Geom::Vector3d.new(0, ssc_b_dist, 0) # Move parallel to Y axis
        tr3_1 = Geom::Transformation.translation(v3.reverse)
        tr3_2 = Geom::Transformation.translation(v3)  
        group_entities.transform_entities(tr3_1, face9)
        group_entities.transform_entities(tr3_2, face11)
      else
        ssc_str = 'E'
        ssc_b_dist = ssc_b - ssc_d
        p20 = Geom::Point3d.new(0, 0, ssc_g)
        v3 = Geom::Vector3d.new(0, ssc_b_dist, 0) # Move parallel to Y axis
        tr3_1 = Geom::Transformation.translation(v3.reverse)
        tr3_2 = Geom::Transformation.translation(v3)
        group_entities.transform_entities(tr3_1, face9)
      end
      scItemCode = scItemCode + ssc_str
      # Identify the face we want to delete
      # circle_face is defined by 3 points, p1, p3, p5 elevated with ssc_l - ssc_g1
      circle_face = nil
      p1Elevated = Geom::Point3d.new(p1.x, p1.y, ssc_l - ssc_g)
      p3Elevated = Geom::Point3d.new(p3.x, p3.y, ssc_l - ssc_g)
      p5Elevated = Geom::Point3d.new(p5.x, p5.y, ssc_l - ssc_g)

      group.entities.grep(Sketchup::Face).each do |face|
        if  face.classify_point(p1Elevated) == Sketchup::Face::PointOnVertex && 
            face.classify_point(p3Elevated) == Sketchup::Face::PointOnVertex && 
            face.classify_point(p5Elevated) == Sketchup::Face::PointOnVertex
          circle_face = face
        end
        area_square_inches += face.area
      end

      # Deduct the faces from total area, transform in m2 and delete the faces
      area_square_inches  = area_square_inches - circle_face.area
      ssc_area            = area_square_inches * conversion_factor
      circle_face.erase!

      # Move p6 to Origin and rotate the piece
      v4 = Geom::Vector3d.new(0, 0, 0) - p6.vector_to(p20)
      tr4 = Geom::Transformation.translation(v4)
      group_entities.transform_entities(tr4.invert!, group_entities.to_a)
      ro = Geom::Transformation.rotation(ORIGIN, X_AXIS, -90.degrees)
      group_entities.transform_entities(ro, group_entities.to_a)

      # Set the name of the group, example: -SCC A_400 B_300 D_250 G_25 G1_25 L_300 Area_0.3392
      ssc_a_str       = ssc_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      ssc_b_str       = ssc_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      ssc_d_str       = ssc_d.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      ssc_g_str       = ssc_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      ssc_g1_str      = ssc_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      ssc_l_str       = ssc_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")
      ssc_area_str    = ssc_area.round(4).to_s

      ssc_group_name  =   "-" + scItemCode +
                          " A_"       + ssc_a_str   +
                          " B_"       + ssc_b_str   + 
                          " D_"       + ssc_d_str   + 
                          " G_"       + ssc_g_str   + 
                          " G1_"      + ssc_g1_str  + 
                          " L_"       + ssc_l_str   + 
                          " Area_"    + ssc_area_str

      # Check if the component is present in the model
      existing_component = model.definitions[ssc_group_name]
      if existing_component
        group.erase!
        UI.messagebox('Another Component with the same name is in the model.
          A new instance of this component is placed in the model origin')
          trans = Geom::Transformation.new
          component_new_instance = model.active_entities.add_instance(Sketchup.active_model.definitions[ssc_group_name], trans)
          number = Sketchup.active_model.definitions[ssc_group_name].count_instances
          component_new_instance.name = number.to_s
      else # Add component and it's attributes
        component_instance = group.to_component
        comp_def = component_instance.definition
        comp_def.name = ssc_group_name

        AttrCreate.CreateGeneralAttributes(comp_def, componentUnits, scItemCode)

        AttrCreate.CreateDimensionAttributes(comp_def, 'a', ssc_a_str, 'STRING', 'A', 'A[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'b', ssc_b_str, 'STRING', 'B', 'B[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'd', ssc_d_str, 'STRING', 'D', 'D[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g', ssc_g_str, 'STRING', 'G', 'G[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'g1', ssc_g1_str, 'STRING', 'G1', 'G1[mm]', 'VIEW')        
        AttrCreate.CreateDimensionAttributes(comp_def, 'l', ssc_l_str, 'STRING', 'L', 'L[mm]', 'VIEW')
        AttrCreate.CreateDimensionAttributes(comp_def, 'uarea', ssc_area_str, 'STRING', 'Area', 'Area[m2]', 'VIEW')

        AttrCreate.CreateFormulaAttributes(comp_def, 'uairspeed', 'STRING', 'uAirSpeed', 'Air Speed[m/s]', 'VIEW', 'uairflow/3600/(smallest(a*b,PI()*d*d/4)/1000000)')

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
# SC.run