class Member::TentsController < Member::WebsiteController
  before_filter :has_boat?
  before_filter :fetch_team, :has_tents?
  def index
    fetch_tent_positions
  end
  
  def show
    #@tent = @team.tent
  end
  
  def update
    @tent_position = TentPosition.find(params[:id])
    @tent = @team.tents.find_empty(:first)
    @tent = @team.tents.find_main(:first, :order=>"updated_at desc") unless @tent
    if @tent
      unless  @tent_position.status == "available"
       @tent.errors.add_to_base('Sorry, this tent position is reserved already') 
      else
       @tent.reserved(@tent_position)
      end
    else
     @tent = @team.tents.find_main(:first)
     @tent.errors.add_to_base('You have reserved all available tent positions for your team')
    end
    fetch_tent_positions
    render :update do |page|
      page.replace_html "tent_positions", :partial => "tent_location"
    end
  end
  
  def unreserved
    @tent_position = TentPosition.find(params[:id])
    @tent = @team.tents.find_by_location(@tent_position.number.to_s)
    if @tent
      @tent.unreserved(@tent_position)
    end
    fetch_tent_positions
    render :update do |page|
      page.replace_html "tent_positions", :partial => "tent_location"
    end  
  end
  
  private
  def fetch_tent_positions
    @tents = @team.tents.find_main(:all)
    @tent_postions = TentPosition.find(:all, :order=>"number")
  end
  
  def has_tents?
    @team.tents.size > 0 ? true : access_denied
  end
end
