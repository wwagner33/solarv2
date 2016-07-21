class Score # < ActiveRecord::Base

  def self.informations(user_id, at_id, related: nil)
    at = at_id.is_a?(AllocationTag) ? at_id : AllocationTag.find(at_id)

    assignments    = Assignment.joins(:academic_allocations, :schedule).includes(academic_allocation_users: :assignment_comments)
                    .where(academic_allocations: { allocation_tag_id:  at.id })
                    .select("assignments.*, schedules.start_date AS start_date, schedules.end_date AS end_date")
                    .order("start_date") if at.is_student?(user_id)
    discussions    = Discussion.posts_count_by_user(user_id, at_id)
    history_access = LogAccess.where(log_type: LogAccess::TYPE[:group_access], user_id: user_id, allocation_tag_id: related || at.related).limit(5)
    public_files   = PublicFile.where(user_id: user_id, allocation_tag_id: at_id)

    exams           = Exam.joins(:academic_allocations, :schedule).includes(:academic_allocation_users)
                      .where(academic_allocations: { allocation_tag_id:  at.id })
                      .select("exams.*, schedules.start_date AS start_date, schedules.end_date AS end_date")
                      .order("start_date")
                        
    [assignments, discussions, exams, history_access, public_files]
  end
end
