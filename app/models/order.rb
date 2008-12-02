class Order < ActiveRecord::Base
  belongs_to :team
  belongs_to :user
  
  has_many :extras_orders, :dependent=>:destroy
  # =============
  # = Constants =
  # =============
  
  CARD_TYPES = ['Visa', 'MasterCard', 'American Express', 'Discover']
  # ===============
  # = Secure attr =
  # ===============
  attr_protected :customer_ip, :gateway_message, :boat_pay, :total_pay, :credit_card
  serialize :credit_card, ActiveMerchant::Billing::CreditCard
  
  
  validates_uniqueness_of :team_id, :scope => [:team_id, :status], :if => :allow_validation

  validates_associated :team, :user
  
  validates_inclusion_of  :status, :in => %w(open processed prepared canceled failed)
  
  def after_initialize
    self.status = 'open'
  end
  
  def allow_validation
    self.status == 'processed'
  end
  
  def calculate_boat_pay
    team.price
  end
  
  def extras_pay
    s = 0
    extras_orders.each {|e| s+=e.pay}
    return s
  end
    
  def calculate_total_pay
    calculate_boat_pay + extras_pay
  end
  
  def process
    populate_tent(team.tent) if !team.tent.nil?
    self.status = "processed"
    self.boat_pay = calculate_boat_pay
    self.total_pay = calculate_total_pay
    self.save!
  end
  
  def activate
    return false unless  self.valid?
    user.to_captain
    team.activate
    OrderNotifier.send("deliver_processed", self)
    true
  end
  
  def failed!
    populate_tent(team.tent) if !team.tent.nil?
    self.status = 'failed'
    self.save!
  end
  
  private
  def populate_tent(tent)
   extras_orders << ExtrasOrder.create({
                                        :extras_id => tent.id,
                                        :extras_type => "Tent",
                                        :pay => tent.price
                                      })
  end
end