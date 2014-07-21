say "1..4"
say .okay
say .else

if .name eq "test-name-value"
  say "ok\t\t- .name eq \"test-name-value\""
else
  say "fail\t\t- .name eq \"test-name-value\""
end

if .value eq "test-value"
  say "ok\t\t- .value eq \"test-value\""
else
  say "fail\t\t- .value eq \"test-value\""
end
