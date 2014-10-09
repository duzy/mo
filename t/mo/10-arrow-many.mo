say("1..2")

for ->*[1, 3] do {
    if .name eq 'test-child-1'
      say(.okay)
    elsif .name eq 'test-child-2'
      say(.okay)
    else
      say("xx\t- [0, 1]; " ~ .name)
    end
}
