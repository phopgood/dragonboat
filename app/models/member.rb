class Member < ActiveRecord::Base
  has_enumerated  :type, :class_name => 'MemberType',:foreign_key => 'type_id'
  has_enumerated  :invitation_status, :class_name => 'Status',:foreign_key => 'invitation_status_id'
  has_enumerated  :waiver_status, :class_name => 'Status',:foreign_key => 'waiver_status_id'
  belongs_to :user, :include=>[:person]
  belongs_to :team, :include=>[:captain]
  belongs_to :type, :class_name => 'MemberType',:foreign_key => 'type_id'
  belongs_to :invitation_status, :class_name => 'Status',:foreign_key => 'invitation_status_id'
  belongs_to :waiver_status, :class_name => 'Status',:foreign_key => 'waiver_status_id'
  
  scope_out :active,
            :conditions => "invitation_status_id=#{Status.find_invitation_by_name('confirmed').id} AND waiver_status_id=#{Status.find_waiver_by_name('accept').id}"
  scope_out :confirmed_and_unread,
            :conditions => "invitation_status_id=#{Status.find_invitation_by_name('confirmed').id} AND waiver_status_id=#{Status.find_waiver_by_name('unread').id}"        
  scope_out :accessible,
            :conditions => "invitation_status_id=#{Status.find_invitation_by_name('confirmed').id} AND waiver_status_id<>#{Status.find_waiver_by_name('decline').id}"        
 
  scope_out :paddlers,
            :conditions => "type_id=#{MemberType[:paddler].id}"
          
  scope_out :accessibled_paddlers,
            :conditions => "type_id=#{MemberType[:paddler].id} AND invitation_status_id=#{Status.find_invitation_by_name('confirmed').id} AND waiver_status_id<>#{Status.find_waiver_by_name('decline').id}"
         
  scope_out :declined_paddlers,
            :conditions => "type_id=#{MemberType[:paddler].id} AND waiver_status_id=#{Status.find_waiver_by_name('decline').id}"
  
  validates_presence_of  :type_id,:waiver_status_id,:invitation_status_id
  validates_associated :team, :user

  #invatation status : unconfirmed, confirmed
  #sign waver: unread, accept, decline
  HUMANIZED_ATTRIBUTES = {
    :confirm => "Accept the invitation",
    :accept => "The terms consent",
    :sign_waiver_notice => "Your Full Name"
  }
  
  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  attr_accessor :accept, :confirm
  attr_accessor :validation_mode
  
   def validate    
    if self.validation_mode == :waiver_form   
      for attr_name in [:confirm]
        errors.add_on_blank(attr_name, 'is required')
      end
    
    if !self.is_unconfirmed? 
      errors.add(:accept, 'is required. If you are accepting the invitation, you need to digitally sign our liability release waiver') if self.waiver_status_id != Status.find_waiver_by_name('accept').id
      errors.add_on_blank(:sign_waiver_notice, 'is required. If you are accepting the invitation, you need to digitally sign our liability release waiver')
    end
    
    end
   end
  
  def accept=(checked)
    @accept = checked.to_i
    if checked.to_i == 1
      self.waiver_status_id = Status.find_waiver_by_name('accept').id
    else
      self.waiver_status_id = Status.find_waiver_by_name('decline').id
    end
  end
  
   def confirm=(checked)
    @confirm= checked
    if checked == "yes"
      self.invitation_status_id = Status.find_invitation_by_name('confirmed').id
    else
      self.invitation_status_id = Status.find_invitation_by_name('unconfirmed').id
    end
  end
  
  def accept
    @accept  if @accept 
  end
  
  def confirm
   @confirm  if @confirm  
  end
  
  def after_initialize
    self.waiver_status_id = Status.find_waiver_by_name('unread').id unless self.waiver_status_id 
    self.invitation_status_id = Status.find_invitation_by_name('unconfirmed').id unless self.invitation_status_id 
  end
  
  def after_save
    if  !self.is_unconfirmed? && self.is_accept? && type.name == 'co-captain'
      user.to_captain
    end
  end
  
  def invite
    unless self.invitation_status.name == 'confirmed'
      update_attribute(:invitation_status_id, Status.find_invitation_by_name('confirmed').id) 
      MemberNotifier.send("deliver_confirmed", self)
      true
    else
      false
    end
  end
  
  def after_destroy
    user.destroy
  end
  
  def is_unconfirmed?
    self.invitation_status_id == Status.find_invitation_by_name('unconfirmed').id
  end
  
  def is_accept?
    self.waiver_status_id == Status.find_waiver_by_name('accept').id
  end
  
  def date_of_signature
    waiver_sign_at.strftime("%d.%m.%Y") if waiver_sign_at
  end
end
