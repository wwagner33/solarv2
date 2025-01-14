class ToolsController < ApplicationController

  layout false

  def equalities
    at_id = active_tab[:url][:allocation_tag_id]
    if at_id.blank?
      authorize! :preview, Webconference, { on: @at_id, accepts_general_profile: true }
    else
      raise CanCan::AccessDenied unless AllocationTag.find(at_id).is_student_or_responsible_or_observer?(current_user.id)
    end

    @equalities = []

    if params[:ac_id].blank?
      if params[:id].blank?
        @equalities = []
      else
        @tool = params[:tool_type].constantize.find(params[:id])
        acs   = @tool.academic_allocations
        eq_acs = AcademicAllocation.where(equivalent_academic_allocation_id: acs.map(&:id))
        @equalities << eq_acs.collect{|ac| ac.academic_tool_type.constantize.find(ac.academic_tool_id)}
        @equalities = @equalities.flatten.compact.uniq

        eq_id = acs.map(&:equivalent_academic_allocation_id).first
        ac = AcademicAllocation.find(eq_id) unless eq_id.blank?
        @equal_to = ac.academic_tool_type.constantize.joins(:academic_allocations).where(academic_allocations: {id: eq_id}).first rescue []
      end
    else
      @tool = params[:tool_type].constantize.joins(:academic_allocations).where(academic_allocations: {id: params[:ac_id]}).first

      eq_acs = AcademicAllocation.where(equivalent_academic_allocation_id: params[:ac_id])
      @equalities << eq_acs.collect{|ac| ac.academic_tool_type.constantize.find(ac.academic_tool_id)}
      @equalities = @equalities.flatten

      ac = AcademicAllocation.find(params[:ac_id])
      eq_ac = AcademicAllocation.find(ac.equivalent_academic_allocation_id) rescue nil
      @equal_to = eq_ac.academic_tool_type.constantize.find(eq_ac.try(:academic_tool_id)) unless eq_ac.blank?
    end
  rescue => error
    Rails.logger.info "[APP] [ERROR] [#{Time.now}] [#{error}] params: #{params.as_json}"
  end

end
