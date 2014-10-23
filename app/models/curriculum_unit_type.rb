class CurriculumUnitType < ActiveRecord::Base
  include Taggable
  include ActiveModel::ForbiddenAttributesProtection

  has_many :curriculum_units
  has_many :offers,  through: :curriculum_units, uniq: true
  has_many :groups,  through: :offers, uniq: true
  has_many :courses, through: :offers, uniq: true

  def tool_name
    tn = case id
      when 3; "course"
      when 7; "course"
      when 4; "module"
      else
       "curriculum_unit"
     end
    I18n.t(tn, "curriculum_units.index")
  end

  def detailed_info
    { curriculum_unit_type: description }
  end

end


