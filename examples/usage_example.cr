require "../src/aws-dynamodb"
require "./video_progress_model"
require "./video_progress_repository"

client = Aws::DynamoDB::Client.new(
  region: ENV["AWS_REGION"]? || "us-east-1",
  aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"]? || "",
  aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]? || "",
  endpoint: ENV["DYNAMODB_ENDPOINT"]?
)

repo = VideoProgressRepository.new(client)

user_id = "user_123"
video_id = "video_456"

puts "=== Creating/updating video progress ==="
progress = repo.update_position(
  user_id: user_id,
  video_id: video_id,
  position: 120.5,
  duration: 300.0
)

puts "User: #{progress.user_id}"
puts "Video: #{progress.video_id}"
puts "Position: #{progress.watch_position}s"
puts "Duration: #{progress.duration}s"
puts "Percentage: #{progress.percentage}%"
puts "Completed: #{progress.completed?}"
puts "Last watched: #{progress.last_watched_at}"

puts "\n=== Fetching a single progress entry ==="
found = repo.find(user_id, video_id)
if found
  puts "Found! Position: #{found.watch_position}s (#{found.percentage}%)"
else
  puts "Not found"
end

puts "\n=== Updating to near completion ==="
progress = repo.update_position(
  user_id: user_id,
  video_id: video_id,
  position: 290.0,
  duration: 300.0
)
puts "New position: #{progress.watch_position}s (#{progress.percentage}%)"
puts "Marked as completed: #{progress.completed?}"

puts "\n=== Fetching every video for the user ==="
repo.update_position(user_id, "video_789", 50.0, 200.0)
repo.update_position(user_id, "video_101", 180.0, 200.0)

all_progress = repo.find_all_by_user(user_id)
puts "Total videos: #{all_progress.size}"
all_progress.each do |item|
  puts "  - #{item.video_id}: #{item.percentage}% (completed: #{item.completed?})"
end

puts "\n=== Fetching incomplete videos only ==="
incomplete = repo.find_incomplete_by_user(user_id)
puts "Incomplete videos: #{incomplete.size}"
incomplete.each do |item|
  puts "  - #{item.video_id}: #{item.percentage}%"
end

puts "\n=== Deleting a progress entry ==="
repo.delete(user_id, "video_789")
puts "Deleted video_789"

all_progress = repo.find_all_by_user(user_id)
puts "Total after deletion: #{all_progress.size}"
