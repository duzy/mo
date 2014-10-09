say("1..8")

if 1
  say("ok")
end

if 0
  say("xx")
end

if 1
  if 0
    say("xx")
  end
end

if 1
  say("ok")
  if 0
    say("xx")
  end
  if 1
    say("ok")
  end
else
  say("xx")
end

unless 0
  say("ok")
end

unless 0
  say("ok")
else
  say("xx")
end

unless 0
  say("ok")
elsif 1
  say("xx")
else
  say("xx")
end

unless 1
  say("xx")
elsif 1
  say("ok")
else
  say("xx")
end

if 1 say("ok"); end
if 0 say("xx"); end
