class Api::VideoProgress::Update < ApiAction
  post "/api/videos/:video_id/progress" do
    user_id = current_user.id.to_s
    video_id = video_id_param

    watch_position = params.get(:watch_position).to_f
    duration = params.get(:duration).to_f

    progress = video_progress_repo.update_position(
      user_id: user_id,
      video_id: video_id,
      position: watch_position,
      duration: duration
    )

    json({
      success: true,
      data:    {
        user_id:         progress.user_id,
        video_id:        progress.video_id,
        watch_position:  progress.watch_position,
        duration:        progress.duration,
        percentage:      progress.percentage,
        completed:       progress.completed,
        last_watched_at: progress.last_watched_at.to_rfc3339,
      },
    })
  end

  private def video_id_param : String
    video_id
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
