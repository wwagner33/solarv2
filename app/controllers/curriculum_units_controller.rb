class CurriculumUnitsController < ApplicationController

  include CurriculumUnitsHelper
  include DiscussionPostsHelper
  include MessagesHelper

  before_filter :prepare_for_group_selection, :only => [:show, :participants, :informations]

  #  load_and_authorize_resource

  ##
  # Apresentacao de todas as informacoes relevantes para o usuario
  ##
  def show
    curriculum_data

    allocation_tags = AllocationTag.find_related_ids(@allocation_tag_id).join(', ');

    # relacionado diretamente com a allocation_tag
    group = AllocationTag.where("id IN (#{allocation_tags}) AND group_id IS NOT NULL").first.group

    # offer
    al_offer = AllocationTag.where("id IN (#{allocation_tags}) AND offer_id IS NOT NULL").first
    offer = al_offer.nil? ? nil : al_offer.offer

    # curriculum_unit
    al_c_unit = AllocationTag.where("id IN (#{allocation_tags}) AND curriculum_unit_id IS NOT NULL").first
    curriculum_unit = al_c_unit.nil? ? CurriculumUnit.find(active_tab[:url]['id']) : al_c_unit.curriculum_unit

    message_tag = get_label_name(group, offer, curriculum_unit)

    # retorna aulas, posts nos foruns e mensagens relacionados a UC mais atuais
    @lessons = Lesson.to_open(@allocation_tag_id)
    @discussion_posts = list_portlet_discussion_posts allocation_tags
    @messages = return_messages(current_user.id, 'portlet', message_tag)

    # destacando dias que possuem eventos
    schedules_events = Schedule.all_by_allocation_tags(allocation_tags)
    @scheduled_events = schedules_events.collect { |schedule_event|
      [schedule_event['start_date'], schedule_event['end_date']]
    }.flatten.uniq

  end

  def destroy
    @curriculum_unit.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  def informations
    curriculum_data

    allocations = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    allocation_offer = AllocationTag.all(:conditions => "id IN (#{allocations.join(', ')}) AND offer_id IS NOT NULL").first

    @offer = allocation_offer.offer
  end

  def participants
    curriculum_data

    # retorna perfil em que se pede matricula (~aluno)
    @student_profile = student_profile

    # retorna participantes da turma (que nao sejam responsaveis)
    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocations = AllocationTag.find_related_ids(allocation_tag_id)

    responsible = false
    @participants = CurriculumUnit.class_participants_by_allocations allocations, responsible

  end

  private

  def curriculum_data
    # localiza unidade curricular
    @curriculum_unit = CurriculumUnit.find(active_tab[:url]['id'])

    @allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocations = AllocationTag.find_related_ids(@allocation_tag_id)
    responsible = true
    @responsible = CurriculumUnit.class_participants_by_allocations allocations, responsible

  end

end
