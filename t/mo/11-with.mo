say "1..6"

with ->child[0] do {
    say .okay

    if .name eq "test-child-1"
      say "ok\t\t- .name eq \"test-child-1\""
    else
      say "fail\t\t- .name eq \"test-child-1\""
    end
}

with ->child[1]
  do {
      say .okay

      if .name eq "test-child-2"
        say "ok\t\t- .name eq \"test-child-2\""
      else
        say "fail\t\t- .name eq \"test-child-2\""
      end
  }

with ->child{ .name eq "test-child-2" }
    do {
        say "ok\t\t- with ->child{ .name eq \"test-child-2\" }"
        if .name eq "test-child-2"
          say "ok\t\t- .name eq \"test-child-2\""
        else
          say "fail\t\t- .name eq \"test-child-2\""
        end
    }
