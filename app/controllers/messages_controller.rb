class MessagesController < ApplicationController
  include FilesHelper
  include MessagesHelper
  include SysLog::Actions

  before_filter :prepare_for_group_selection, only: [:index]

  ## [inbox, outbox, trashbox]
  def index
    allocation_tag_id = active_tab[:url][:allocation_tag_id]

    @show_system_label = allocation_tag_id.nil?

    @box = option_user_box(params[:box])
    @page = (params[:page] || 1).to_i

    search = {}
    search.merge!({user: params[:user]}) unless params[:user].blank?
    search.merge!({subject: params[:subject]}) unless params[:subject].blank?

    options = {page: @page, ignore_at: true}
    options.merge!(option_search_for(params[:search_for]))

    @messages = Message.by_box(current_user.id, @box, allocation_tag_id, options, search)

    @limit = Rails.application.config.items_per_page
    @min = (@page * @limit) - @limit

    @unreads = @messages.first.try(:unread) rescue 0
    if @unreads.nil?
      @unreads = Message.get_count_unread_in_inbox(current_user.id, allocation_tag_id, options.except(:ignore_at), search)
    end
    render partial: 'list' unless params[:page].nil?
  end

  def pending
    # used at the uc home
    @page = (params[:page] || 1).to_i

    @messages = Message.by_box(current_user.id, 'inbox', active_tab[:url][:allocation_tag_id], { only_unread: true, page: @page, ignore_at: true })

    @limit = Rails.application.config.items_per_page
    @min = (@page * @limit) - @limit
    @total = @messages.try(:first).total_messages rescue 0

    respond_to do |format|
      format.json { render json: @messages }
      format.js
    end
  end

  def search
    @box = option_user_box(params[:box])
    @page = (params[:page] || 1).to_i

    options = {page: @page, ignore_at: true}
    options.merge!(option_search_for(params[:search_for]))

    @messages = Message.by_box(current_user.id, @box, active_tab[:url][:allocation_tag_id], options, { user: params[:user], subject: params[:subject] })

    @limit = Rails.application.config.items_per_page
    @min = (@page * @limit) - @limit

    render partial: 'list'
  end

  def new
    authorize! :index, Message, { on: [@allocation_tag_id  = active_tab[:url][:allocation_tag_id]], accepts_general_profile: true } unless active_tab[:url][:allocation_tag_id].nil?
    @message = Message.new
    @message.files.build

    @reply_to = [User.find(params[:user_id]).to_msg] unless params[:user_id].nil? # se um usuário for passado, colocá-lo na lista de destinatários
    @reply_to = [{resume: t("messages.support")}] unless params[:support].nil?

    @support = params[:support]

    render layout: false unless @support || params[:layout]
  end

  def show
    @message = Message.find(params[:id])
    sent_by_responsible = @message.allocation_tag.is_responsible?(@message.sent_by.id) unless @message.allocation_tag_id.blank?
    LogAction.create(log_type: LogAction::TYPE[:update], user_id: current_user.id, ip: get_remote_ip, description: "message: #{@message.id} read message from #{sent_by_responsible ? 'responsible' : 'other'}", allocation_tag_id: @message.allocation_tag_id) rescue nil
    change_message_status(@message.id, "read", @box = params[:box] || "inbox")
  end

  def reply
    @original = Message.find(params[:id])
    raise CanCan::AccessDenied unless @original.user_has_permission?(current_user.id)

    @allocation_tag_id = active_tab[:url][:allocation_tag_id]

    @message = Message.new subject: @original.subject
    @message.files.build

    @message.content = reply_msg_template

    unless @allocation_tag_id.nil?
      allocation_tag      = AllocationTag.find(@allocation_tag_id)
      @group              = allocation_tag.group
      @contacts           = User.all_at_allocation_tags(allocation_tag.related, Allocation_Activated, true)
    else
      @contacts = current_user.user_contacts.map(&:user)
    end

    @files = @original.files

    @reply_to = []
    case params[:type]
      when "reply"
        @reply_to = [@original.sent_by.to_msg]
        @message.subject = "#{t(:reply, scope: [:messages, :subject])} #{@message.subject}"
      when "reply_all"
        @reply_to = @original.users.uniq.map(&:to_msg)
        @message.subject = "#{t(:reply, scope: [:messages, :subject])} #{@message.subject}"
      when "forward"
        # sem contato default
        @message.subject = "#{t(:forward, scope: [:messages, :subject])} #{@message.subject}"
    end
  end

  def create
    @allocation_tag_id = params[:allocation_tag_id].blank? ? active_tab[:url][:allocation_tag_id] : params[:allocation_tag_id]

    # is an answer
    if params[:message][:original].present?
      @original = Message.find(params[:message].delete(:original)) # precisa para a view de new, caso algum problema aconteca
      original_files = @original.files.where(message_files: {id: params[:message].delete(:original_files)})
    end

    begin
      Message.transaction do
        @message = Message.new(message_params, without_validation: true)
        @message.sender = current_user
        @message.allocation_tag_id = @allocation_tag_id

        raise "error" if params[:message][:contacts].nil? && params[:message][:support].blank?

        # raise "error" if params[:message][:contacts].empty?
        # emails = User.joins('LEFT JOIN personal_configurations AS nmail ON users.id = nmail.user_id')
                      # .where("(nmail.message IS NULL OR nmail.message=TRUE)")
                      # .where(id: params[:message][:contacts].split(',')).pluck(:email).flatten.compact.uniq

        # @message.files << original_files if original_files and not original_files.empty?

        emails = []
        unless params[:message][:contacts].nil?
                emails = User.joins('LEFT JOIN personal_configurations AS nmail ON users.id = nmail.user_id')
                      .where("(nmail.message IS NULL OR nmail.message=TRUE)")
                      .where(id: params[:message][:contacts].split(',')).pluck(:email).flatten.compact.uniq
        end
        emails << 'atendimento@virtual.ufc.br' unless params[:message][:support].blank?

        @message.files << original_files if original_files and not original_files.empty?
        @message.save!
        #Thread.new do
          #Notifier.send_mail(emails, @message.subject, new_msg_template, @message.files, current_user.email).deliver
        #end
        Job.send_mass_email(emails, @message.subject, new_msg_template, @message.files.to_a, current_user.email)
      end

      redirect_to outbox_messages_path, notice: t(:mail_sent, scope: :messages)
    rescue => error
      unless @allocation_tag_id.nil?
        allocation_tag      = AllocationTag.find(@allocation_tag_id)
        @group              = allocation_tag.group
        @contacts           = User.all_at_allocation_tags(RelatedTaggable.related(group_id: @group.id), Allocation_Activated, true)
      else
        @contacts = current_user.user_contacts.map(&:user)
      end
      @message.files.build

      @message.errors.each do |attribute, erro|
        @attribute = attribute
      end
      @reply_to = []
      # @reply_to = User.where(id: params[:message][:contacts].split(',')).select("id, (name||' <'||email||'>') as resume")
      @reply_to = User.where(id: params[:message][:contacts].split(',')).select("id, (name||' <'||email||'>') as resume") unless params[:message][:contacts].blank?

      @support = params[:message][:support]

      #flash.now[:alert] = @message.errors.full_messages.join(', ')
      render :new
    end
  end

  ## [read, unread, trash, restore]
  def update
    begin
      Message.transaction do
        params[:id].split(',').map(&:to_i).each { |i| change_message_status(i, params[:new_status], option_user_box(params[:box])) }
      end
      render json: {success: true}
    rescue => error
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  def count_unread
    render json: { unread: (Message.by_box(current_user.id, 'inbox', active_tab[:url][:allocation_tag_id], {ignore_at: true, page: 1, only_unread: true}).first.try(:total_messages) rescue 0) }
  end

  def download_files
    file = MessageFile.find(params[:file_id])
    raise CanCan::AccessDenied unless file.message.user_has_permission?(current_user.id)

    download_file(inbox_messages_path, file.attachment.path, file.attachment_file_name)
  end

  def find_users
    @allocation_tags_ids = AllocationTag.get_by_params(params, related = true)[:allocation_tags]

    raise CanCan::AccessDenied if current_user.is_researcher?(@allocation_tags_ids)
    authorize! :show, CurriculumUnit, { on: @allocation_tags_ids, read: true }

    @users = User.all_at_allocation_tags(@allocation_tags_ids, Allocation_Activated, true)
    @allocation_tags_ids = @allocation_tags_ids.join('_')
    render partial: 'users'
  rescue => error
    render json: { success: false, alert: t('messages.errors.permission') }, status: :unprocessable_entity
  end

  def contacts
    @content_student = false
    @content_responsibles = false
    unless (@allocation_tag_id = params[:allocation_tag_id]).nil?
      allocation_tag = AllocationTag.find(@allocation_tag_id)
      @group         = allocation_tag.group
    # else
    #   @contacts = current_user.user_contacts.map(&:user)
    end
    @contacts = User.all_at_allocation_tags(allocation_tag.try(:related), Allocation_Activated, true)

    @reply_to = (params[:reply_to].blank? ? [] : User.where(id: params[:reply_to].split(',')).map(&:to_msg))

    unless params[:reply_to].blank? || @contacts.blank?
      @list = @contacts.find_all_by_id(params[:reply_to].split(','))
      @content_student = @list.any? { |u| u.types.to_i==Profile_Type_Student }
      @content_responsibles = @list.any? { |u| u.types.to_i==Profile_Type_Class_Responsible }
    end

    render partial: 'contacts'
  end

  private

    def new_msg_template
      system_label = not(@allocation_tag_id.nil?)

      %{
        <b>#{t(:mail_header, scope: :messages)} #{current_user.to_msg[:resume]}</b><br/>
        #{@message.labels(current_user.id, system_label) if system_label}<br/>
        ________________________________________________________________________<br/><br/>
        #{@message.content}
      }
    end

    def reply_msg_template
      %{
        <br/><br/>----------------------------------------<br/>
        #{t(:from, scope: [:messages, :show])} #{@original.sent_by.to_msg[:resume]}<br/>
        #{t(:date, scope: [:messages, :show])} #{l(@original.created_at, format: :clock)}<br/>
        #{t(:subject, scope: [:messages, :show])} #{@original.subject}<br/>
        #{t(:to, scope: [:messages, :show])} #{@original.users.map(&:to_msg).map{ |c| c[:resume] }.join(',')}<br/>
        #{@original.content}
      }
    end

    def option_user_box(type)
      return type if ['outbox', 'trashbox'].include?(type)
      'inbox'
    end

    def option_search_for(type)
      return {type.to_sym => true} if ['only_read', 'only_unread'].include?(type)
      {}
    end

    def message_params
      params.require(:message).permit(:subject, :content, :contacts, files_attributes: :attachment)
    end

end
