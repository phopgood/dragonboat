class TentPosition < ActiveRecord::Base
  STATUS = [["Available", "available"],  ["Reserved", "reserved"]]
  validates_numericality_of :number
  validates_uniqueness_of :number
  validates_inclusion_of :status, :in=>%w( available reserved )
end
