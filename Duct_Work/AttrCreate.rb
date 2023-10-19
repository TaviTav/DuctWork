# Create attributes for ductwork components
# Version Beta 1
# Bugs:
# To do: MORE TESTING IS REQUIRED !!!!

# v1 changes:
# Adding attributes to the component

module AttrCreate

  def self.CreateGeneralAttributes(compDef, compUnits, itemCodeValue)
    # Set length units for component
    compDef.set_attribute 'dynamic_attributes', '_lengthunits', compUnits

    # Create ItemCode attribute, itemCodeValue
    compDef.set_attribute 'dynamic_attributes', 'itemcode', itemCodeValue
    compDef.set_attribute 'dynamic_attributes', '_itemcode_label', 'ItemCode'

    # Create Label attribute
    compDef.set_attribute 'dynamic_attributes', 'label', '_'
    compDef.set_attribute 'dynamic_attributes', '_label_units', 'STRING'
    compDef.set_attribute 'dynamic_attributes', '_label_label', 'Label'
    compDef.set_attribute 'dynamic_attributes', '_label_formlabel', 'Label'
    compDef.set_attribute 'dynamic_attributes', '_label_access', 'TEXTBOX'

    # Create Notes attribute
    compDef.set_attribute 'dynamic_attributes', 'notes', '_'
    compDef.set_attribute 'dynamic_attributes', '_notes_units', 'STRING'
    compDef.set_attribute 'dynamic_attributes', '_notes_label', 'Notes'
    compDef.set_attribute 'dynamic_attributes', '_notes_formlabel', 'Notes'
    compDef.set_attribute 'dynamic_attributes', '_notes_access', 'TEXTBOX'

    # Create mH attribute
    compDef.set_attribute 'dynamic_attributes', 'mh', '0'
    compDef.set_attribute 'dynamic_attributes', '_mh_units', 'STRING'
    compDef.set_attribute 'dynamic_attributes', '_mh_label', 'mH'
    compDef.set_attribute 'dynamic_attributes', '_mh_formlabel', 'Mounting Height[m]'
    compDef.set_attribute 'dynamic_attributes', '_mh_access', 'TEXTBOX'

    # Create uAirFlow attribute
    compDef.set_attribute 'dynamic_attributes', 'uairflow', '1000'
    compDef.set_attribute 'dynamic_attributes', '_uairflow_units', 'STRING'
    compDef.set_attribute 'dynamic_attributes', '_uairflow_label', 'uAirFlow'
    compDef.set_attribute 'dynamic_attributes', '_uairflow_formlabel', 'Air Flow[m3/h]'
    compDef.set_attribute 'dynamic_attributes', '_uairflow_access', 'TEXTBOX'

    # Create uPressureLoss attribute
    compDef.set_attribute 'dynamic_attributes', 'upl', '0'
    compDef.set_attribute 'dynamic_attributes', '_upl_units', 'STRING'
    compDef.set_attribute 'dynamic_attributes', '_upl_label', 'uPressureLoss'
    compDef.set_attribute 'dynamic_attributes', '_upl_formlabel', 'Pressure Loss[Pa]'
    compDef.set_attribute 'dynamic_attributes', '_upl_access', 'TEXTBOX'

  end  # def self.CreateGeneralAttributes

  def self.CreateDimensionAttributes(compDef, dimName, dimValue, dimUnits, dimLabel, dimFormLabel, dimAccess)
    # Create a custom attribute with given values
    compDef.set_attribute 'dynamic_attributes', dimName, dimValue
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_units', dimUnits
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_label', dimLabel
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_formlabel', dimFormLabel
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_access', dimAccess
    
  end  # def self.CreateDimensionAttributes

  def self.CreateFormulaAttributes(compDef, dimName, dimUnits, dimLabel, dimFormLabel, dimAccess, dimFormula)
    # Create a custom attribute with given values and formula
    compDef.set_attribute 'dynamic_attributes', dimName, ''
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_units', dimUnits
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_label', dimLabel
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_formlabel', dimFormLabel
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_access', dimAccess
    compDef.set_attribute 'dynamic_attributes', '_' + dimName + '_formula', dimFormula

  end  # def self.CreateDimensionAttributes

end # module AttrCreate