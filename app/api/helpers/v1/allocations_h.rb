module V1::AllocationsH

  ## remover
  def allocate_professors(group, cpfs)
    group.allocations.where(profile_id: 17).update_all(status: 2) # cancel all previous allocations

    cpfs = cpfs.reject { |c| c.empty? }
    cpfs.each do |cpf|
      professor = verify_or_create_user(cpf)
      group.allocate_user(professor.id, 17)
    end
  end

  # cancel all previous allocations and create new ones to groups
  def cancel_previous_and_create_allocations(groups, user, profile_id)
    # only curriculum units which type is 2
    # user.groups([profile_id], nil, nil, 2).each do |group|
    #   group.change_allocation_status(user.id, 2, profile_id: profile_id) # cancel all users previous allocations as profile_id
    # end

    groups.each do |group|
      group.allocate_user(user.id, profile_id)
    end
  end

  def cancel_all_allocations(profile_id, semester_id)
    ucs = CurriculumUnitType.find(2).curriculum_units.map(&:id)
    params = { curriculum_unit_id: ucs }
    params.merge!(semester_id: semester_id) #unless config not defined
    taggables = RelatedTaggable.joins(:offer).where(offers: params).select('COALESCE(group_at_id, offer_at_id) AS at').map(&:at).map(&:to_i)
    Allocation.where(allocation_tag_id: taggables, profile_id: profile_id).update_all updated_at: Time.now, status: Allocation_Cancelled
  end

  def get_profile_id(profile)
    ma_config = User::MODULO_ACADEMICO
    distant_professor_profile = (ma_config.nil? || !(ma_config['professor_profile'].present?) ? 17 : ma_config['professor_profile'])

    case profile.to_i
      when 1; 18 # tutor a distância UAB
      when 2; 4 # tutor presencial
      when 3; distant_professor_profile # professor titular UAB
      when 4; 1  # aluno
      when 17; 2 # professor titular
      when 18; 3 # tutor a distância
      else profile # corresponds to profile with id == allocation[:perfil]
    end
  end
  ## remover

  def allocate(params, cancel = false)
    object = ( params[:id].nil? ?  get_destination(params[:curriculum_unit_code], params[:course_code], params[:group_code], params[:semester]) : params[:type].capitalize.constantize.find(params[:id]) )
    users  = get_users(params)

    raise ActiveRecord::RecordNotFound if users.empty?

    object.cancel_allocations(nil, params[:profile_id]) if params[:remove_previous_allocations]

    users.each do |user|
      user.cancel_allocations(params[:profile_id]) if params[:remove_user_previous_allocations]
      object.send(cancel ? :cancel_allocations : :allocate_user, user.id, params[:profile_id])
    end
  end

  def get_users(params, users=[])
    users << case 
    when params[:user_id].present?
      User.find(params[:user_id])
    when params[:users_ids].present?
      User.where(id: params[:users_ids])
    when params[:cpf].present?
      User.where(cpf: params[:cpf].delete('.').delete('-')).first
    else 
      User.where(cpf: params[:cpfs])
    end


    users << import_users(params) if (params[:cpf].present? or params[:cpfs].present?) and params[:ma]
    users.compact.flatten
  end

  def import_users(params)
    users = []
    [params[:cpf] || params[:cpfs]].flatten.each do |cpf|
      users << verify_or_create_user(cpf)
    end
    users
  end

end