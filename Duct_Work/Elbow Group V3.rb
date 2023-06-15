# Rectangular elbow
# Fix the bug for r=0
# Get a reference to the current active model
model = Sketchup.active_model

# Declare variables (initial values)
elbow_a         = 300.mm
elbow_a1        = 300.mm # only for 90° elbows. a1 = a for the other angles
elbow_b         = 300.mm
elbow_g         = 25.mm
elbow_g1        = 25.mm
elbow_r         = 100.mm
start_a         = 0.0
end_a           = 90.degrees
elbow_area      = 0.0
filter_message  = false

if end_a < 90.degrees
  albow_a1 = albow_a
end

# Create a custom dialog box and retrieve user input
def self.get_user_input(defaults)
  prompts = ['A (mm):', 'A1 (mm):', 'B (mm):', 'G (mm):', 'G1 (mm):', 'R (mm):', 'V° (degrees):']
  results = UI.inputbox(prompts, defaults, 'Enter Values')
  return results.map(&:to_f) if results
end

# Main code
begin
  # Get user input for variables
  input_defaults = [elbow_a, elbow_a1, elbow_b, elbow_g, elbow_g1, elbow_r, end_a.radians.round(0)]
  user_input = get_user_input(input_defaults)
  
  # Check if user input is canceled or if the correct number of values were entered
  if user_input.nil? || user_input.size != 7
    filter_message = true
    return
  end

  # Extract values from user input
  elbow_a, elbow_a1, elbow_b, elbow_g, elbow_g1, elbow_r = user_input[0..5].map { |value| value.inch }
  end_a = user_input[6].degrees

  # Check if variables are valid
  # a, a1, b > 0 and g, g1, r >= 0 and 0 < end_a <= 90 and a<>g, a<>g1, a1<>g, a1<>g1
  if elbow_a > 0 && elbow_a1 > 0 && elbow_b > 0 && elbow_g >= 0 && elbow_r >= 0 && end_a > 0 && end_a <= 90.degrees && elbow_a >= elbow_a1

    # Set the name of the group, example: -CR V_45° R_100 A_300 A1_300 xB G_300 G1_200 Area_0.8339
    elbow_r_str       = elbow_r.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    elbow_a_str       = elbow_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    elbow_a1_str      = elbow_a1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    elbow_g_str       = elbow_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    elbow_g1_str      = elbow_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    elbow_area_str    = elbow_area.round(4).to_s

    elbow_group_name  = "-CR V°_" + (end_a * 180 / Math::PI).round.to_s + 
                        " R_" + elbow_r_str + 
                        " A_" + elbow_a_str + 
                        " A1_" + elbow_a1_str + 
                        " xB" + 
                        " G_" + elbow_g_str + 
                        " G1_" + elbow_g1_str + 
                        " Area_"

    # Check if another group or component with a matching name (ignoring the last 6 characters) already exists in the drawing
    existing_group = model.entities.grep(Sketchup::Group).find { |g| g.name[0...-6] == elbow_group_name }
    existing_component = model.entities.grep(Sketchup::ComponentInstance).find { |c| c.name[0...-6] == elbow_group_name }

    if existing_group || existing_component
      UI.messagebox('Another group or component with the same name already exists!')
      filter_message = true
      return
    else
      # Create a new group
      group = model.active_entities.add_group

      # Get the group entities
      group_entities = group.entities
    end

    # Draw arc1, 2, 3, 4
    center_point_arc1 = Geom::Point3d.new(-elbow_r, elbow_g, 0)
    center_point_arc2 = Geom::Point3d.new(-elbow_r, elbow_g, elbow_b)
    center_point_arc3 = Geom::Point3d.new(-elbow_r + elbow_a - elbow_a1, elbow_g, 0)
    center_point_arc4 = Geom::Point3d.new(-elbow_r + elbow_a - elbow_a1, elbow_g, elbow_b)

    arc1 = group_entities.add_arc(center_point_arc1, X_AXIS, Z_AXIS, elbow_r, start_a, end_a)
    arc2 = group_entities.add_arc(center_point_arc2, X_AXIS, Z_AXIS, elbow_r, start_a, end_a)
    arc3 = group_entities.add_arc(center_point_arc3, X_AXIS, Z_AXIS, elbow_r + elbow_a1, start_a, end_a)
    arc4 = group_entities.add_arc(center_point_arc4, X_AXIS, Z_AXIS, elbow_r + elbow_a1, start_a, end_a)

    num_segments  = arc1[0].curve.count_edges # all arcs have the same number of segments
    arc1_points   = arc1[0].curve.vertices.map(&:position)
    arc2_points   = arc2[0].curve.vertices.map(&:position)
    arc3_points   = arc3[0].curve.vertices.map(&:position)
    arc4_points   = arc4[0].curve.vertices.map(&:position)

    connecting_edges1 = []
    connecting_edges2 = []
    connecting_edges3 = []
    connecting_edges4 = []
    (0..num_segments).each do |i| # add a bunch of useless connecting edges until you find another solution
      connecting_edges1 << group_entities.add_line(arc1_points[i], arc2_points[i])
      connecting_edges2 << group_entities.add_line(arc3_points[i], arc4_points[i])
      connecting_edges3 << group_entities.add_line(arc1_points[i], arc3_points[i])
      connecting_edges4 << group_entities.add_line(arc2_points[i], arc4_points[i])
    end

    # Create the faces of the arcs
    (0..num_segments - 1).each do |i|
      face = group_entities.add_face(arc1[i].curve.edges[0], arc2[i].curve.edges[0], connecting_edges1[i], connecting_edges1[i + 1])
      face = group_entities.add_face(arc3[i].curve.edges[0], arc4[i].curve.edges[0], connecting_edges2[i], connecting_edges2[i + 1])
      face = group_entities.add_face(arc1[i].curve.edges[0], arc3[i].curve.edges[0], connecting_edges3[i], connecting_edges3[i + 1])
      face = group_entities.add_face(arc2[i].curve.edges[0], arc4[i].curve.edges[0], connecting_edges4[i], connecting_edges4[i + 1])
    end

    # Hide the connecting edges of the arcs
    connecting_edges1[1..-2].each { |edge| edge.visible = false }
    connecting_edges2[1..-2].each { |edge| edge.visible = false }
    connecting_edges3[1..-2].each { |edge| edge.visible = false }
    connecting_edges4[1..-2].each { |edge| edge.visible = false }

    # Generate the rest of the points, edges and faces
    point1 = Geom::Point3d.new(elbow_a, 0, 0)
    point2 = arc3_points.first
    point3 = arc1_points.first
    point4 = Geom::Point3d.new(0, 0, elbow_b)
    point5 = Geom::Point3d.new(elbow_a, 0, elbow_b)
    point6 = arc4_points.first
    point7 = arc2_points.first
    point8 = arc1_points.last
    point9 = arc3_points.last

    # Deal with particularities on lower part
    if end_a < 90.degrees || elbow_a == elbow_a1 # point10 = point9 if end_a<90 sau elbow_a = elbow_a1
      point10 = point9
    else # add some geometry, extra edges and faces
      point10 = Geom::Point3d.new(point8.x, point8.y + elbow_a1, point8.z)
      edge15  = group_entities.add_line(point8, point10)
      edge25  = group_entities.add_line(point8, point9)
      edge28  = group_entities.add_line(point9, point10)
      face    = group_entities.add_face(edge15, edge25, edge28)
    end

    # Create elbow_g1 side on lower part
    temp_point11  = Geom::Point3d.new(point10.x - elbow_g1, point10.y, point10.z)
    temp_point12  = Geom::Point3d.new(point8.x - elbow_g1, point8.y, point8.z)
    edge14        = group_entities.add_line(point8, temp_point12)
    edge16        = group_entities.add_line(point10, temp_point11)
    edge14.parent.entities.transform_entities(Geom::Transformation.rotation(point8, Z_AXIS, -90.degrees + end_a), edge14)
    edge16.parent.entities.transform_entities(Geom::Transformation.rotation(point10, Z_AXIS, -90.degrees + end_a), edge16)
    point11       = edge16.end
    point12       = edge14.end
    point13       = arc2_points.last
    point14       = arc4_points.last

    # Deal with particularities on higher part
    if end_a < 90.degrees || elbow_a == elbow_a1 # point15 = point14 dc end_a<90 sau elbow_a = elbow_a1
      point15 = point14
    else # add some geometry, extra edges and faces
      point15 = Geom::Point3d.new(point13.x, point13.y + elbow_a1, point13.z)
      edge19  = group_entities.add_line(point13, point15)
      edge24  = group_entities.add_line(point10, point15)
      edge26  = group_entities.add_line(point13, point14)
      edge27  = group_entities.add_line(point9, point14)
      edge29  = group_entities.add_line(point14, point15)
      face    = group_entities.add_face(edge19, edge26, edge29)
      face    = group_entities.add_face(edge24, edge27, edge28, edge29)
      edge25.hidden = true
      edge26.hidden = true
    end

    # Create elbow_g1 side on higher part
    temp_point16  = Geom::Point3d.new(point15.x - elbow_g1, point15.y, point15.z)
    temp_point17  = Geom::Point3d.new(point13.x - elbow_g1, point13.y, point13.z)
    edge18        = group_entities.add_line(point13, temp_point17)
    edge20        = group_entities.add_line(point15, temp_point16)
    edge18.parent.entities.transform_entities(Geom::Transformation.rotation(point13, Z_AXIS, -90.degrees + end_a), edge18)
    edge20.parent.entities.transform_entities(Geom::Transformation.rotation(point15, Z_AXIS, -90.degrees + end_a), edge20)
    point16       = edge20.end
    point17       = edge18.end

    # Finish the rest of the geometry
    edge1   = group_entities.add_line(ORIGIN, point1)
    edge2   = group_entities.add_line(point1, point2)
    edge3   = group_entities.add_line(point2, point3)
    edge4   = group_entities.add_line(point3, ORIGIN)
    edge5   = group_entities.add_line(point4, point5)
    edge6   = group_entities.add_line(point5, point6)
    edge7   = group_entities.add_line(point6, point7)
    edge8   = group_entities.add_line(point7, point4)
    edge9   = group_entities.add_line(ORIGIN, point4)
    edge10  = group_entities.add_line(point1, point5)
    edge11  = group_entities.add_line(point3, point7)
    edge12  = group_entities.add_line(point2, point6)
    edge13  = group_entities.add_line(point11, point12)
    #edge14 = is defined
    edge15  = group_entities.add_line(point8, point10)
    #edge16 = is defined
    edge17  = group_entities.add_line(point16, point17)
    #edge18 = is defined
    edge19  = group_entities.add_line(point13, point15)
    #edge20 = is defined
    edge21  = group_entities.add_line(point12, point17)
    edge22  = group_entities.add_line(point11, point16)
    edge23  = group_entities.add_line(point8, point13)
    edge24  = group_entities.add_line(point10, point15)

    face = group_entities.add_face(edge1, edge2, edge3, edge4)
    face = group_entities.add_face(edge2, edge6, edge10, edge12)
    face = group_entities.add_face(edge5, edge6, edge7, edge8)
    face = group_entities.add_face(edge4, edge8, edge9, edge11)
    face = group_entities.add_face(edge13, edge14, edge15, edge16)
    face = group_entities.add_face(edge14, edge18, edge21, edge23)
    face = group_entities.add_face(edge17, edge18, edge19, edge20)
    face = group_entities.add_face(edge16, edge20, edge22, edge24)

    # Calculate the elbow area
    conversion_factor = 0.00064516
    group.entities.grep(Sketchup::Face).each do |face|
      area_square_inches  = face.area
      area_square_meters  = area_square_inches * conversion_factor
      elbow_area          += area_square_meters
    end
    # Assign the name to the group including the last 6 digits, Area of the elbow
    elbow_area_str    = elbow_area.round(4).to_s
    elbow_group_name  = elbow_group_name + elbow_area_str
    group.name        = elbow_group_name

  else  # values are not good, try again
    msg = 
    'Invalid values detected!!! 
    
    Check the following conditions:
    A, A1, B > 0, 
    A > A1
    G, R >= 0
    0 < V° <= 90'
    UI.messagebox(msg)
    filter_message = true
    return
  end

rescue => e
  # filter some common errors and do not message the user
  if !filter_message
     UI.messagebox("Grrrr some unknown error occurred: #{e.message}") 
  else
    # nothing here
  end
end