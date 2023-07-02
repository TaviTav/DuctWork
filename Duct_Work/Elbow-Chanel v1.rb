# Rectangular ramification elbow - chanel
# Version 1
# Bugs:
# To do: instead of group make a dynamic component

# Declare variables (initial values)

# elbow_a       = 300.mm # rcc_d1
# elbow_a1      = 300.mm # rcc_d, only for 90° elbows. a1 = a for the other angles
# elbow_b       = 300.mm # rcc_b
# elbow_g       = 25.mm  # rcc_g
# elbow_g1      = 25.mm  # rcc_g1
# elbow_r       = 100.mm # rcc_r
elbow_area      = 0.0

# red_a   = 300.mm # rcc_c1
# red_b   = 300.mm # rcc_b
# red_c   = 400.mm # rcc_c
# red_d   = 300.mm # rcc_b
# red_e   = 100.mm # rcc_e 
# red_f   = 0.mm
# red_g   = rcc_g
# red_g1  = rcc_g
# red_l   = 400.mm # rcc_l
red_area  = 0.0

rcc_b     = 300.mm # elbow_b, red_b, red_d
rcc_c     = 400.mm # red_c
rcc_c1    = 300.mm # red_a
rcc_d     = 400.mm # elbow_a1
rcc_d1    = 300.mm # elbow_a
rcc_e     = 100.mm # red_e
rcc_g     = 25.mm  # elbow_g, elbow_g1, red_g, red_g1
rcc_g1    = 25.mm  # elbow_g1
rcc_l     = 400.mm # red_l
rcc_r     = 100.mm # elbow_r
start_a   = 0.0
end_a     = 90.degrees
rcc_area  = 0.0

rcc_rotation        = 0.degrees
area_square_inches  = 0.0
conversion_factor   = 0.00064516
filter_message      = false

# Create a custom dialog box and retrieve user input
def self.get_user_input(defaults)
  prompts = ['B (mm):', 'C (mm):', 'C1 (mm):', 'G (mm):', 'L (mm):', 'D (mm):', 'D1 (mm):','G1 (mm)' 'R (mm):', '<° (degrees):', 'Elbow Rotation (-90, 0, 90):']
  results = UI.inputbox(prompts, defaults, 'Enter Values for Ramification chanel + elbow')
  return results.map(&:to_f) if results
end

# Main code
begin
  # Get user input for variables
  input_defaults = [rcc_b, rcc_c, rcc_c1, rcc_g, rcc_l, rcc_d, rcc_d1, rcc_g1, rcc_r, end_a.radians.round(0), rcc_rotation.radians.round(0)]
  user_input = get_user_input(input_defaults)
  
  # Check if user input is canceled or if the correct number of values were entered
  if user_input.nil? || user_input.size != 11
    filter_message = true
    return
  end

  # Extract values from user input
  rcc_b, rcc_c, rcc_c1, rcc_g, rcc_l, rcc_d, rcc_d1, rcc_g1, rcc_r = user_input[0..8].map { |value| value.inch }
  end_a = user_input[9].degrees
  rcc_rotation = user_input[10].degrees

  # Check if values are valid
  # B, C, C1, L, D, D1 > 0; G, G1 > 25mm; 0° <  Elbow Angle < 90°; Elbow Rotation -90, 0 or 90° 
  if rcc_b > 0 && rcc_c > 0 # finish this condition !!!!!!!!!!!!!!!!!!!!!
    
    #######################################################################
    #######################################################################
    #######################################################################
    # A1 = A if <° < 90
    if (end_a * 180 / Math::PI) < 90
      elbow_a1 = elbow_a
    end

    # Set the name of the group, example: -RCC <°_90 Rot°_0 R_100 B_300 C_400 C1_300 D_400 D1_300 E_100 G_25 G1_25 L_400  Area_0.5279
    rcc_angle_str   = end_a * 180 / Math::PI).round.to_s
    rcc_rot_str     = rcc_rotation * 180 / Math::PI).round.to_s
    rcc_r_str       = rcc_r.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_b_str       = rcc_b.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_c_str       = rcc_c.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_c1_str      = rcc_c1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_d_str       = rcc_d.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_d1_str      = rcc_d1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_e_str       = rcc_e.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_g_str       = rcc_g.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_g1_str      = rcc_g1.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_l_str       = rcc_l.to_s.gsub(/\s+/, "").gsub(/mm/, "")
    rcc_area_str    = rcc_area.round(4).to_s

    rcc_group_name  = "-RCC <°_"  + rcc_angle_str + 
                      " Rot°_"    + rcc_rot_str   +
                      " R_"       + rcc_r_str     + 
                      " B_"       + rcc_b_str     + 
                      " C_"       + rcc_c_str     + 
                      " C1_"      + rcc_c1_str    + 
                      " D_"       + rcc_d_str     + 
                      " D1_"      + rcc_d1_str    +     
                      " E_"       + rcc_e_str     +                                         
                      " G_"       + rcc_g_str     + 
                      " G1_"      + rcc_g1_str    +
                      " L_"       + rcc_l_str     +  
                      " Area_"

    # Check if another group or component with a matching name (ignoring the last 6 characters) already exists in the drawing
    existing_group = model.entities.grep(Sketchup::Group).find { |g| g.name[0...-6] == rccgroup_name }
    existing_component = model.entities.grep(Sketchup::ComponentInstance).find { |c| c.name[0...-6] == rcc_group_name }

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
    #######################################################################
    #######################################################################
    #######################################################################

    # Create the geometry inside the group
    # abordare: desenam cot, rotim, aflam aria? il facem grup?
    #           desenam reductie / canal, aflam aria?, il facem grup?
    #           denumim grupul rcc, aflam aria?


  else # values are not good, try again
    msg = 
    'Invalid values detected!!! 
    
    Check the following conditions:
    B, C, C1, L, D, D1 > 0; 
    G, G1 > 25mm; 
    0° <  Elbow Angle < 90°; 
    Elbow Rotation -90, 0 or 90° '
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