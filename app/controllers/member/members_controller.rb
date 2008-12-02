class Member::MembersController < Member::WebsiteController 
  before_filter :has_boat?
  before_filter :fetch_team
  before_filter :set_types, :except=>[:index]
  include ApplicationHelper
  def index
    order = case params[:sort]
      when 'name'             then 'persons.first_name, persons.last_name'
      when 'name_reverse'      then 'persons.first_name desc, persons.last_name desc'
      when 'email'             then 'persons.email'
      when 'email_reverse'      then 'persons.email desc'
      when 'type'             then 'member_types.name'
      when 'type_reverse'      then 'member_types.name desc'
      when 'invitation'             then 'statuses.name'
      when 'invitation_reverse'      then 'statuses.name desc'
      when 'waiver_status'             then 'statuses.name'
      when 'waiver_status_reverse'      then 'statuses.name desc'  
      when 'created_at'   then 'members.created_at'
      when 'created_at_reverse'   then 'members.created_at DESC'
      else 'members.created_at DESC'
    end
    @members = @team.members.paginate(:page => params[:page], 
                   :include =>[:type, :invitation_status,:waiver_status],
                   :joins => "LEFT JOIN users ON users.id = members.user_id LEFT JOIN persons ON persons.id = users.person_id",
                   :per_page =>APP_CONFIG["admin_per_page"],
                   :order => order)
    @members_count = @team.members.count(:all,
                   :include =>[:type, :invitation_status,:waiver_status],
                   :joins => "LEFT JOIN users ON users.id = members.user_id LEFT JOIN persons ON persons.id = users.person_id"
                 )
  end
  
  def new
    @member = @team.members.build
    @member.invitation_status_id = invitation_status_id_by_name('confirmed')
    @user = User.new
    @person = @user.person
  end
  
  def create
    @member = @team.members.build(params[:member])
    @user = User.new(params[:user])
    @person = @user.person
    @person.attributes = (params[:person])
    @person.validation_mode = :member 
    if @person.valid?
      @user.generate_account(@team.name)
    end
    @member.user = @user
   # @roles = [Role.find_by_name(params[:user]['role'])]
   # @user.person.attributes = (params[:person])
   # @user.roles = @roles
    respond_to do |format|
      if @person.valid? && @user.valid? && @member.valid? && @person.save! && @user.save! && @member.save!
        flash[:notice] = 'Member was successfully created.'
        format.html { redirect_to member_team_members_url(@team) }
        format.xml  { render :xml => @member, :status => :created, :location => @member }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @member.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @member = @team.members.find(params[:id])
    @user = @member.user
    @person = @user.person
  end
  
  def update
    @member = @team.members.find(params[:id])
    @user = @member.user
    @person = @user.person
    @person.attributes = (params[:person])
    @person.validation_mode = :member 
    @member.attributes=(params[:member])
    respond_to do |format|    
    if  @person.valid? && @user.valid? && @member.valid? && @person.save! && @user.save! && @member.save!
        flash[:notice] = 'Member was successfully updated.'
        format.html { redirect_to member_team_members_url(@team) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @member.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    @member = @team.members.find(params[:id])
    @user = @member.user
    @person = @user.person
  end

  def confirm
    @member = Member.find(params[:id])  
    flash[:notice] = "Member #{@member.user.person.name} was invited to join the team." if @member && @member.invite 
    redirect_to member_team_members_url(@team)
  end
  
  def access
    @member = @team.members.find(params[:id])
    @user = @member.user
    @person = @user.person
  end
  
  private
  def set_types
    @types = MemberType.find(:all, :order => "name")
    @statuses = Status.find_invitation(:all, :order => "name")
  end
end