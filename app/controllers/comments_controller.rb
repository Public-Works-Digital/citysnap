class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_issue

  def create
    @comment = @issue.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @issue, notice: "Comment added successfully."
    else
      redirect_to @issue, alert: @comment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @comment = @issue.comments.find(params[:id])

    # Only the comment author or officers can delete
    if @comment.user == current_user || current_user.officer_user_type?
      @comment.destroy
      redirect_to @issue, notice: "Comment deleted successfully."
    else
      redirect_to @issue, alert: "You are not authorized to delete this comment."
    end
  end

  private

  def set_issue
    @issue = Issue.find(params[:issue_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
