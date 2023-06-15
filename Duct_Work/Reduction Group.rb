# Rectangular reduction

# Get a reference to the current active model
model = Sketchup.active_model

# Declare variables (initial values)
red_a     = 400.mm
red_b     = 200.mm
red_c     = 200.mm
red_d     = 400.mm
red_e     = 0.mm
red_f     = 0.mm
red_g     = 25.mm
red_g1    = 25.mm
red_l     = 200.mm
red_area  = 0.0
filter_message = false

# Create a custom dialog box and retrieve user input
def self.get_user_input(defaults)
  prompts = ['A (mm):', 'B (mm):', 'C (mm):', 'D (mm):', 'E (mm):', 'F (mm):', 'G (mm):', 'G1 (mm):', 'Lred (mm):']
  results = UI.inputbox(prompts, defaults, 'Enter Values')
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
  red_a, red_b, red_c, red_d, red_e, red_f, red_g, red_g1, red_l = user_input[0..8].map { |value| value.inch }

  # Check if values are valid
  # A, B, C, D, G, G1, L > 0 
  if red_a > 0 && red_b > 0 && red_c > 0 && red_d > 0 && red_g > 0 && red_g1 > 0 && red_l > 0 

    # Set the name of the group, example: -RED A_400 B_200 C_200 D_400 E_0 F_0 G_25 G1_25 L_200 L_250 Area_0.3497
    red_l_total     = red_l + red_g + red_g1
    red_a_str       = red_a.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_b_str       = red_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_c_str       = red_c.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_d_str       = red_d.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_e_str       = red_e.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_f_str       = red_f.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_g_str       = red_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_g1_str      = red_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_l_str       = red_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_l_total_str = red_l_total.inch.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    red_area_str    = red_area.round(4).to_s

    red_group_name  = "-RED A_" + red_a_str + 
                      " B_" + red_b_str + 
                      " C_" + red_c_str + 
                      " D_" + red_d_str + 
                      " E_" + red_e_str + 
                      " F_" + red_f_str + 
                      " G_" + red_g_str + 
                      " G1_" + red_g1_str + 
                      " L_" + red_l_total_str + 
                      " Area_"

    # Check if another group or component with a matching name (ignoring the last 6 characters) already exists in the drawing
    existing_group = model.entities.grep(Sketchup::Group).find { |g| g.name[0...-6] == red_group_name }
    existing_component = model.entities.grep(Sketchup::ComponentInstance).find { |c| c.name[0...-6] == red_group_name }

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

    # Create the geometry inside the group
    point1  = Geom::Point3d.new(red_a, 0, 0)
    point2  = Geom::Point3d.new(red_a, red_g, 0)
    point3  = Geom::Point3d.new(0, red_g, 0)
    point4  = Geom::Point3d.new(0, 0, red_b)
    point5  = Geom::Point3d.new(red_a, 0, red_b)
    point6  = Geom::Point3d.new(0, red_g, red_b)
    point7  = Geom::Point3d.new(red_a, red_g, red_b)
    point8  = Geom::Point3d.new(red_e, red_g + red_l, red_f)
    point9  = Geom::Point3d.new(red_e + red_c, red_g + red_l, red_f)
    point10 = Geom::Point3d.new(red_e, red_g + red_l, red_f + red_d)
    point11 = Geom::Point3d.new(red_e + red_c, red_g + red_l, red_f + red_d)
    point12 = Geom::Point3d.new(red_e, red_g + red_l + red_g1, red_f)
    point13 = Geom::Point3d.new(red_e + red_c, red_g + red_l + red_g1, red_f)
    point14 = Geom::Point3d.new(red_e, red_g + red_l + red_g1, red_f + red_d)
    point15 = Geom::Point3d.new(red_e + red_c, red_g + red_l + red_g1, red_f + red_d)

    edge1   = group_entities.add_line(ORIGIN, point1)
    edge2   = group_entities.add_line(point1, point2)
    edge3   = group_entities.add_line(point2, point3)
    edge4   = group_entities.add_line(point3, ORIGIN)
    edge5   = group_entities.add_line(ORIGIN, point4)
    edge6   = group_entities.add_line(point4, point5)
    edge7   = group_entities.add_line(point1, point5)
    edge8   = group_entities.add_line(point3, point6)
    edge9   = group_entities.add_line(point6, point7)
    edge10  = group_entities.add_line(point7, point2)
    edge11  = group_entities.add_line(point4, point6)
    edge12  = group_entities.add_line(point5, point7)
    edge13  = group_entities.add_line(point3, point8)
    edge14  = group_entities.add_line(point2, point9)
    edge15  = group_entities.add_line(point8, point9)
    edge16  = group_entities.add_line(point8, point10)
    edge17  = group_entities.add_line(point9, point11)
    edge18  = group_entities.add_line(point10, point11)
    edge19  = group_entities.add_line(point10, point6)
    edge20  = group_entities.add_line(point11, point7)
    edge21  = group_entities.add_line(point8, point12)
    edge22  = group_entities.add_line(point9, point13)
    edge23  = group_entities.add_line(point10, point14)
    edge24  = group_entities.add_line(point11, point15)
    edge25  = group_entities.add_line(point12, point13)
    edge26  = group_entities.add_line(point13, point15)
    edge27  = group_entities.add_line(point15, point14)
    edge28  = group_entities.add_line(point12, point14)


    face1   = group_entities.add_face(edge1, edge2, edge3, edge4)
    face2   = group_entities.add_face(edge4, edge5, edge8, edge11)
    face3   = group_entities.add_face(edge6, edge9, edge11, edge12)
    face4   = group_entities.add_face(edge2, edge7, edge10, edge12)   
    face5   = group_entities.add_face(edge3, edge13, edge14, edge15)
    face6   = group_entities.add_face(edge8, edge13, edge16, edge19)  
    face7   = group_entities.add_face(edge10, edge14, edge17, edge20) 
    face8   = group_entities.add_face(edge9, edge18, edge19, edge20) 
    face9   = group_entities.add_face(edge15, edge21, edge22, edge25) 
    face10  = group_entities.add_face(edge16, edge21, edge28, edge23) 
    face11  = group_entities.add_face(edge22, edge17, edge24, edge26)
    face12  = group_entities.add_face(edge18, edge23, edge24, edge27)      

    # Calculate the reduction area
    conversion_factor = 0.00064516
    group.entities.grep(Sketchup::Face).each do |face|
      area_square_inches = face.area
      area_square_meters = area_square_inches * conversion_factor
      red_area += area_square_meters
    end

    # Assign the name to the group including the last 6 digits, Area of the reduction
    red_area_str    = red_area.round(4).to_s
    red_group_name  = red_group_name + red_area_str
    group.name      = red_group_name

  else # values are not good, try again
    msg = 
    'Invalid values detected!!! 
    
    Check the following conditions:
    A, B, C, D, G, G1, L > 0'
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