class GroupParticipant < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :group_assignment
  belongs_to :user

  has_many :sent_assignments

  before_save :can_change?, if: "merge.nil?"
  before_destroy :can_change?

  attr_accessor :merge

  def can_change?
    group = group_assignment
    files = group.sent_assignment.try(:assignment_files)
    raise "date_range_expired" unless group.assignment.in_time?(group.academic_allocation.allocation_tag.id)
    raise "evaluated" if group.evaluated?
    raise "has_files" if (not(files.nil?) and files.any?) and files.map(&:user_id).include? user_id
  end

end
