class IssuesController < ApplicationController
  before_action :authenticate_user!, except: %i[ show public ]
  before_action :set_issue, only: %i[  edit update destroy ]

  helper_method :can_edit_issue?

  # GET /issues or /issues.json
  def index
    @issues = current_user.issues.all

    # Apply filters
    if params[:status].present?
      @issues = @issues.where(status: params[:status])
    end

    if params[:category_id].present?
      @issues = @issues.where(category_id: params[:category_id])
    end

    @issues = @issues.order(created_at: :desc)
  end

  # GET /issues/public
  def public
    issues_scope = Issue.where.not(latitude: nil, longitude: nil).includes(:user, :category)

    # Apply status filter
    if params[:status].present?
      issues_scope = issues_scope.where(status: params[:status])
    end

    # Apply category filter
    if params[:category_id].present?
      issues_scope = issues_scope.where(category_id: params[:category_id])
    end

    # Filter by map bounds if provided
    if params[:bounds].present?
      bounds = JSON.parse(params[:bounds])
      issues_scope = issues_scope.within_bounds(
        bounds["south"],
        bounds["west"],
        bounds["north"],
        bounds["east"]
      )
    end

    @pagy, @issues = pagy(issues_scope.order(created_at: :desc), limit: 20)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /issues/1 or /issues/1.json
  def show
    @issue = Issue.find(params[:id])
    @my_issue = user_signed_in? && current_user.issues.exists?(id: @issue.id)
  end

  # GET /issues/new
  def new
    @issue = current_user.issues.new
  end

  # GET /issues/1/edit
  def edit
  end

  # POST /issues or /issues.json
  def create
    @issue = current_user.issues.new(issue_params)

    respond_to do |format|
      if @issue.save
        format.html { redirect_to @issue, notice: "Issue was successfully created." }
        format.json { render :show, status: :created, location: @issue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /issues/1 or /issues/1.json
  def update
    respond_to do |format|
      if @issue.update(issue_params)
        format.html { redirect_to @issue, notice: "Issue was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @issue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1 or /issues/1.json
  def destroy
    @issue.destroy!

    respond_to do |format|
      format.html { redirect_to issues_path, notice: "Issue was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_issue
      @issue = Issue.find(params.expect(:id))

      # Check authorization
      unless can_edit_issue?(@issue)
        respond_to do |format|
          format.html { redirect_to issues_path, alert: "You are not authorized to edit this issue." }
          format.json { head :forbidden }
        end
      end
    end

    # Authorization helper
    def can_edit_issue?(issue)
      return false unless user_signed_in?

      # Officers can edit any issue, citizens can only edit their own
      current_user.officer_user_type? || issue.user_id == current_user.id
    end

    # Only allow a list of trusted parameters through.
    def issue_params
      permitted_params = [ :comment, :photo, :latitude, :longitude, :street_address, :category_id ]

      # Only officers can change status
      permitted_params << :status if current_user&.officer_user_type?

      params.expect(issue: permitted_params)
    end
end
