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

puts "=== Criando/Atualizando progresso de vídeo ==="
progress = repo.update_position(
  user_id: user_id,
  video_id: video_id,
  position: 120.5,
  duration: 300.0
)

puts "Usuário: #{progress.user_id}"
puts "Vídeo: #{progress.video_id}"
puts "Posição: #{progress.watch_position}s"
puts "Duração: #{progress.duration}s"
puts "Percentual: #{progress.percentage}%"
puts "Completo: #{progress.completed}"
puts "Última visualização: #{progress.last_watched_at}"

puts "\n=== Buscando progresso específico ==="
found = repo.find(user_id, video_id)
if found
  puts "Encontrado! Posição: #{found.watch_position}s (#{found.percentage}%)"
else
  puts "Não encontrado"
end

puts "\n=== Atualizando para próximo da conclusão ==="
progress = repo.update_position(
  user_id: user_id,
  video_id: video_id,
  position: 290.0,
  duration: 300.0
)
puts "Nova posição: #{progress.watch_position}s (#{progress.percentage}%)"
puts "Marcado como completo: #{progress.completed}"

puts "\n=== Buscando todos os vídeos do usuário ==="
repo.update_position(user_id, "video_789", 50.0, 200.0)
repo.update_position(user_id, "video_101", 180.0, 200.0)

all_progress = repo.find_all_by_user(user_id)
puts "Total de vídeos: #{all_progress.size}"
all_progress.each do |p|
  puts "  - #{p.video_id}: #{p.percentage}% (completo: #{p.completed})"
end

puts "\n=== Buscando apenas vídeos incompletos ==="
incomplete = repo.find_incomplete_by_user(user_id)
puts "Vídeos incompletos: #{incomplete.size}"
incomplete.each do |p|
  puts "  - #{p.video_id}: #{p.percentage}%"
end

puts "\n=== Deletando um progresso ==="
repo.delete(user_id, "video_789")
puts "Deletado video_789"

all_progress = repo.find_all_by_user(user_id)
puts "Total após deleção: #{all_progress.size}"
