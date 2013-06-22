class Hiring < ActiveRecord::Base
  belongs_to :user
  belongs_to :employee
  belongs_to :restaurant
  belongs_to :department
  belongs_to :termination_reason
  has_many :days_off, :dependent => :destroy
  has_many :employee_warnings, :dependent => :destroy
  has_many :hiring_positions, :dependent => :destroy
  
  
  named_scope :active_hirings, {:conditions => ["termination_date is ?", nil]}
  validates_presence_of :department_id, :start_date
  validates_uniqueness_of :restaurant_id, :scope => [:employee_id], :message => ": This employee already has a contract in this restaurant"
  
  
  def current_employment_cycle
    today = Date.today
    this_years_date = Date.new(today.year, start_date.month, start_date.day)
    if (today > this_years_date)
      this_years_date
    else
      Date.new(today.year - 1, start_date.month, start_date.day)
    end
  end
  
  def current_employment_half_cycle
    today = Date.today
    if start_date.month > 6
      this_years_date = Date.new(today.year, start_date.advance(:month => -6).month, start_date.advance(:month => -6).day)
    else   
      this_years_date = Date.new(today.year - 1, start_date.advance(:month => +6).month, start_date.advance(:month => +6).day)
    end  
    if (today > this_years_date)
      this_years_date
    else
      Date.new(today.year - 1, start_date.month, start_date.day)
    end
  end
  
  def current_days_off_by_type(type)
    days_off.since(current_employment_cycle).by_type(type)
  end
  
  def current_days_off
    days_off.since(current_employment_cycle)
  end
  
  def history_days_off
    days_off.since(start_date)
  end
  
  def current_employee_warnings
    employee_warnings.since(current_employment_half_cycle)
  end 
  
  def history_employee_warnings
    employee_warnings.since(start_date)
  end
  
  def current_employee_warning_total_points
    employee_warnings = current_employee_warnings
    total = 0
    warnings = employee_warnings.collect{|x| total += x.warning.points} 
    return total
  end 
  
  def history_employee_warning_total_points
    employee_warnings = history_employee_warnings
    total = 0
    warnings = employee_warnings.collect{|x| total += x.warning.points} 
    return total
  end 
  
  def self.employment_aniversary(start_date)
    today = Date.today
    # One month range aniversay
    if start_date.month > 1
      aniversary_from_date = Date.new(today.year, start_date.advance(:month => -1).month, start_date.advance(:month => -1).day)
    else   
      aniversary_from_date = Date.new(today.year - 1, 12, start_date.day)
    end 
    
    aniversary_to_date = Date.new(today.year, start_date.month, start_date.day)
    
    if today > aniversary_from_date && today < aniversary_to_date 
      return true
    else
      return false  
    end
  end
  
  def self.employment_health_qualify(start_date)
    today = Date.today
    # Two months after hiring
    if start_date.month < 11
      health_check_date = Date.new(start_date.year, start_date.advance(:month => 2).month, start_date.advance(:month => 2).day)
    else
      health_check_date = Date.new(start_date.year + 1, start_date.advance(:month => -10).month, start_date.advance(:month => -10).day)  
    end    
      
    if today > health_check_date 
      return true
    else
      return false  
    end
  end
  
  def self.employment_visa_expire(expire_date)
    today = Date.today
    # One month before expire
    if expire_date.month > 1
      expire_date_from = Date.new(expire_date.year, expire_date.advance(:month => -1).month, expire_date.advance(:month => -1).day)
    else   
      expire_date_from = Date.new(expire_date.year - 1, 12, expire_date.day)
    end
    if today > expire_date_from 
      return true
    else
      return false  
    end
  end
  
  def self.papelon_alerts
    @alerts = Hash.new
    
    hirings = Hiring.find(:all)
    if ! hirings.nil?
      for hiring in hirings
        @alerts_messages = Array.new
        if ! hiring.start_date.nil?
          if employment_aniversary(hiring.start_date)
             today = Date.today
             aniversary_date = Date.new(today.year, hiring.start_date.month, hiring.start_date.day)
             @alerts_messages << "<span class='item' style='padding-left:10px; background-color:orange;'>The Aniversary is on "+aniversary_date.to_s+"</span><br/>"
          end  
          if hiring.employee.if_w4.blank?
             @alerts_messages << "<span class='item' style='padding-left:10px;'>W4 required</span><br/>"
          end  
          if hiring.employee.if_copy_ssn.blank?
            @alerts_messages << "<span class='item' style='padding-left:10px;'>Copy of SSN required</span><br/>"
          end  
          if hiring.employee.if_copy_id.blank?
            @alerts_messages << "<span class='item' style='padding-left:10px;'>Copy of ID required</span><br/>" 
          end
          if hiring.employee.if_opt_in and !hiring.employee.if_health_insur and employment_health_qualify(hiring.start_date)
            @alerts_messages << "<span class='item' style='padding-left:10px; background-color:orange;'>Check to enroll for Health and/or Dental Insurance</span><br/>" 
          end  
          if ! hiring.employee.visa_exp_date.nil? 
            if employment_visa_expire(hiring.employee.visa_exp_date)
              @alerts_messages << "<span class='item' style='padding-left:10px; background-color:orange;'>The work visa will expire soon or already expired</span><br/>" 
            end
          end
          if @alerts_messages.length > 0
              @alerts[hiring] = @alerts_messages
          end    
        end  
      end
    end  
    return @alerts
  end
  
  def self.today_alert_messages
    @alerts = ""
    
    hirings = Hiring.find(:all)
    if ! hirings.nil?
      for hiring in hirings
        @alerts_messages = ""
        if ! hiring.start_date.nil?
          
          if employment_aniversary(hiring.start_date)
             today = Date.today
             aniversary_date = Date.new(today.year, hiring.start_date.month, hiring.start_date.day)
             @alerts_messages << "The Aniversary is on "+aniversary_date.to_s+" \r\n"
          end  
          if hiring.employee.if_w4.blank?
             @alerts_messages << "W4 required \r\n"
          end  
          if hiring.employee.if_copy_ssn.blank?
            @alerts_messages << "Copy of SSN required \r\n"
          end  
          if hiring.employee.if_copy_id.blank?
            @alerts_messages << "Copy of ID required \r\n"
          end
          if hiring.employee.if_opt_in and !hiring.employee.if_health_insur and employment_health_qualify(hiring.start_date)
            @alerts_messages << "Check to enroll for Health and/or Dental Insurance \r\n" 
          end  
          if ! hiring.employee.visa_exp_date.nil? 
            if employment_visa_expire(hiring.employee.visa_exp_date)
              @alerts_messages << "The work visa will expire soon or already expired \r\n"
            end
          end
          
          
          
          if @alerts_messages != ""
              @alerts << hiring.employee.full_name+" \r\n"
              @alerts << hiring.restaurant.name+" \r\n"
              @alerts << @alerts_messages
              if hiring.current_days_off.size > 0
    						for type in DayOffType.all
    							@alerts << type.name+": "+hiring.current_days_off_by_type(type).size.to_s+" \r\n"
    						end 
    					end
              @alerts << "\r\n"
          end    
        end  
      end
    end  
    AlertMailer.deliver_today_alerts(@alerts)
  end

  def self.get_positions(hiring_id)
    positions = HiringPosition.find(:all, :conditions => ["hiring_id = ? and position_date_finish is ?", hiring_id, nil]).uniq
    return positions
  end
  
  def self.get_history(hiring_id)
    positions = HiringPosition.find(:all, :conditions => ["hiring_id = ?", hiring_id]).uniq
    return positions
  end  
end
