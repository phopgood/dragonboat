class Team < ActiveRecord::Base
  validates_presence_of :name
  belongs_to :boat_type, :foreign_key => 'type_id', :class_name=>"BoatType"
  belongs_to :captain, :foreign_key => 'captain_id', :class_name=>"User"
  belongs_to :image, :foreign_key => 'logo_id', :class_name=>"Image"
 
  has_many :team_extras, :dependent=>:destroy, :foreign_key => 'team_id', :class_name=>"TeamExtras"
 # has_many :extras, :as=>:"items", :through=>:team_extras, :foreign_key => 'team_id', :class_name=>"TeamExtras"
  
  has_many :members, :dependent=>:destroy
  has_many :users, :through => :members
  has_many :tents, :dependent=>:destroy
  
  has_one :order, :dependent=>:destroy
 
  has_enumerated  :status, :class_name => 'Status',:foreign_key => 'status_id'
  
  belongs_to :status
  validates_associated :captain
  validates_uniqueness_of :name, :case_sensitive => false
  
  scope_out :active,
            :conditions => "status_id=#{Status.find_team_by_name('active').id}"
          
  def total
    total = self.price
    team_extras.each {|te| total+= te.extras.price*te.quantity}
    return total
  end

  def price
    boat_type.price
  end
  
  def activate
    set_status('active')
  end
  
  def unactivate
    set_status('unactive')
  end
  
  def status_human_name
    status.name == 'unactive' ? 'unactive (unpaid)' : 'active (paid)'
  end
  
  private
  def set_status(name)
    update_attribute(:status_id, Status.find_team_by_name(name).id)
  end
end
