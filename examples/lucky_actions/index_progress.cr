class Api::VideoProgress::Index < ApiAction
  get "/api/user/video-progress" do
    user_id = current_user.id.to_s
    show_incomplete_only = params.get?(:incomplete_only) == "true"

    progress_list = if show_incomplete_only
                      video_progress_repo.find_incomplete_by_user(user_id)
                    else
                      video_progress_repo.find_all_by_user(user_id)
                    end

    json({
      success: true,
      data:    progress_list.map do |progress|
        {
          user_id:         progress.user_id,
          video_id:        progress.video_id,
          watch_position:  progress.watch_position,
          duration:        progress.duration,
          percentage:      progress.percentage,
          completed:       progress.completed,
          last_watched_at: progress.last_watched_at.to_rfc3339,
        }
      end,
      total: progress_list.size,
    })
  end

  private def video_progress_repo : VideoProgressRepository
    VideoProgressRepository.new(dynamodb_client)
  end

  private def dynamodb_client : Aws::DynamoDB::Client
    Aws::DynamoDB::Client.new(
      region: ENV["AWS_REGION"]? || "us-east-1",
      aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"]? || "",
      aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]? || "",
      endpoint: ENV["DYNAMODB_ENDPOINT"]?
    )
  end
end
