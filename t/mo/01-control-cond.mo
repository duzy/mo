say "1..8"

if 1
  say "ok"
end

if 0
  say "fail"
end

if 1
  if 0
    say "fail"
  end
end

if 1
  say "ok"
  if 0
    say "fail"
  end
  if 1
    say "ok"
  end
else
  say "fail"
end

unless 0
  say "ok"
end

unless 0
  say "ok"
else
  say "fail"
end

unless 0
  say "ok"
elsif 1
  say "fail"
else
  say "fail"
end

unless 1
  say "fail"
elsif 1
  say "ok"
else
  say "fail"
end

if 1 say "ok" ;
if 0 say "fail" ;
