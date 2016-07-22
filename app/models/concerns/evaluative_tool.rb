require 'active_support/concern'
module EvaluativeTool
  extend ActiveSupport::Concern

  included do
    has_many :academic_allocation_users, through: :academic_allocations
  end

  def self.find_tools(ats)
    ats << AllocationTag.find(ats.first).lower_related if ats.size == 1
    AcademicAllocation.find_by_sql <<-SQL
      SELECT DISTINCT(ac.ids), *, ac.ats FROM academic_allocations
       JOIN (
         SELECT array_agg(id) AS ids, 
                academic_tool_id, 
                academic_tool_type, 
                array_agg(allocation_tag_id) AS ats
         FROM academic_allocations 
         WHERE academic_tool_type IN (#{"'"+self.descendants.join("','")+"'"}) 
         AND allocation_tag_id IN (#{ats.uniq.join(',')})
         GROUP BY academic_tool_type, academic_tool_id, evaluative, frequency, final_exam, max_working_hours, equivalent_academic_allocation_id, weight, final_weight
         ) ac ON ac.ids @> ARRAY[academic_allocations.id];
    SQL
  end
 
  def full_period
    date = if respond_to?(:initial_time) 
            I18n.l(initial_time, format: :at_date)
           else
            hours  = (!respond_to?(:start_hour) || start_hour.nil?) ? '' : (!respond_to?(:end_hour) || end_hour.nil?) ? start_hour : [start_hour, end_hour].join(I18n.t('schedules.to'))
            dstart = respond_to?(:schedule) ?  I18n.l(schedule.start_date, format: :normal) : ''
            dend   = respond_to?(:schedule) ?  I18n.l(schedule.end_date, format: :normal) : ''
            I18n.t('editions.evaluative_tools.full_period', dstart: dstart, dend: dend , hours: hours)
           end
  end

  def verify_evaluatives
    academic_allocations.where('evaluative IS TRUE OR frequency IS TRUE').any?
  end

  def can_remove_groups_with_raise
    raise 'dependencies' unless can_remove_groups?
  end

  # filled groups: at groups_controller ; empty groups: before_destroy
  def can_remove_groups?(groups=[])
    begin
      case self.class.to_s
      when 'Assignment'
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: self.id, allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      when 'Discussion'
        if groups.any?
          discussion_posts.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          discussion_posts.empty?
        end
      when 'Exam'
        return false if status && on_going?
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, academic_tool_type: 'Exam', allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      when 'ChatRoom'
        if groups.any?
          user_messages.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          user_messages.empty?
        end
      when 'Webconference'
        return false unless can_destroy?
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, academic_tool_type: 'Webconference', allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      when 'ScheduleEvent'
        return false unless can_change?
        if groups.any?
          academic_allocation_users.joins(:academic_allocation).where(academic_allocations: { academic_tool_id: id, academic_tool_type: 'ScheduleEvent', allocation_tag_id: groups.map(&:allocation_tag).map(&:id) }).empty?
        else
          academic_allocation_users.empty?
        end
      else
        true
      end
    rescue => error
      return false
    end
  end

  # filled groups: at groups_controller ; empty groups: before_destroy
  def can_unbind?(groups=[])
    case self.class.to_s
    when 'Exam'
      !(status && on_going?)
    when 'Webconference'
      !(is_over? && is_recorded)
    else
      true
    end
  end

  private

    def self.descendants
      ActiveRecord::Base.descendants.select{ |c|
        c.included_modules.include?(EvaluativeTool)
      }.map(&:name).map(&:to_s)
    end
end
