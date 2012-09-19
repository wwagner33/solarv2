module Taggable

  def self.included(base)   
    base.before_destroy :unallocate_if_possible
    base.after_create :allocation_tag_association
    base.after_create :user_editor_allocation

    base.has_one :allocation_tag, :dependent => :destroy
    base.has_many :allocations, :through => :allocation_tag
    base.has_many :users, :through => :allocation_tag

    attr_accessor :user_id
  end

  def unallocate_if_possible
    return false if self.has_any_lower_association?
    unallocate_if_up_to_one_user
  end

  def unallocate_if_up_to_one_user
    if at_most_one_user_allocated?
      @user_id = self.allocations.select(:user_id).first.user_id if self.allocations.count > 0
      unallocate_user_in_lower_associations(user_id) if user_id
      return true
    end
    return false
  end

  def at_most_one_user_allocated?
    not (self.allocations.select("DISTINCT user_id").count  > 1)
  end

  def unallocate_user(user_id)
    Allocation.destroy_all(user_id: user_id, allocation_tag_id: self.allocation_tag.id)
  end

  def unallocate_user_in_related(user_id)
    self.allocation_tag.unallocate_user_in_related(user_id)
  end

  def allocation_tag_association
    AllocationTag.create({self.class.name.underscore.to_sym => self})
  end

  def user_editor_allocation
    allocate_user(user_id, Curriculum_Unit_Initial_Profile) if user_id
  end

  def allocate_user(user_id, profile_id)
    Allocation.create(:user_id => user_id, :allocation_tag_id => self.allocation_tag.id, :profile_id => profile_id, :status => Allocation_Activated)
  end

  def is_only_user_allocated?(user_id)
    self.allocation_tag.is_only_user_allocated_in_related?(user_id)
  end

  def can_destroy?
    ((is_up_to_one_user?) and (not has_any_lower_association?))
  end

  private
  def unallocate_user_in_lower_associations(user_id)    
    self.lower_associated_objects do |down_associated_object| 
      down_associated_object.unallocate_user_in_lower_associations(user_id)
    end if self.respond_to?(:lower_associated_objects)
    unallocate_user(user_id)
  end

end