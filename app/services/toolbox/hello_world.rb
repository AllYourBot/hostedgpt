class Toolbox::HelloWorld < Toolbox
  describe :hi, "This is a description for hi"

  def hi(name_s:)
    "Hello, #{name_s}!"
  end

  def get_eligibility(birthdate_s:, gender_enum_male_female:)
    raise "Pretend this call failed because of a network issue"
  end
end
