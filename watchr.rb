system("racket app.rkt &")
watch("\.rkt") do |match|
  racket_pid = `ps aux | grep racket | grep -v grep | awk '{print $2}'`
  system("kill #{racket_pid}") unless racket_pid.empty?
  system("racket app.rkt &")
end

