say("1..21")

if 1 == 1
  say("ok\t\t- if 1 == 1")
end

if 0 == 1
  say("fail\t\t- if 0 == 1")
end

if 0 != 0
  say("fail\t\t- if 0 != 0")
end

if not 1 == 1
  say("fail\t\t- if not 1 == 1")
end

if not not 1 == 0
  say("fail\t\t- if  not not 1 == 0")
end

unless not 1 == 0
  say("fail\t\t- unless not 1 == 0")
end

if not '1' eq "1"
  say("fail\t\t- if not '1' eq \"1\"")
end

if not 1 eq "1"
  say("fail\t\t- if not 1 eq \"1\"")
end

if not '1' eq 1
  say("fail\t\t- if not 1 eq \"1\"")
end

if 1 eq "0"
  say("fail\t\t- if 1 eq \"0\"")
end

if "0" eq 1
  say("fail\t\t- if \"0\" eq 1")
end

if "0" == 1
  say("fail\t\t- if \"0\" == 1")
end

if 0 == "1"
  say("fail\t\t- if 0 == \"1\"")
end

if not 1 == "1"
  say("fail\t\t- if not 1 == \"1\"")
end

if not "0" == 0
  say("fail\t\t- if not \"0\" == 0")
end

if 123 == "123"
  say("ok\t\t- if 123 == \"123\"")
end
if not 123 == "123"
  say("fail\t\t- if not 123 == \"123\"")
end

if "1" eq "1"
  if "0" eq "1"
    say("fail\t\t- if '0' == '1'")
  end
end

if not "true" == "true"
  say("fail\t\t- if not \"true\" == \"true\"")
end
if not "true" == "false"
  say("fail\t\t- if not \"true\" == \"false\"")
end
if not "any" == "aaaaaaaaaaaaaaaaaaa"
  say("fail\t\t- if not \"any\" == \"aaaaaaaaaaaaaaaaaaa\"")
end
if not "any" < 1
  say("fail\t\t- if not \"any\" < 1")
end

if not "a1"
  say("ok\t\t- if not \"a1\"")
end
if not not "a1"
  say("fail\t\t- if not not \"a1\"")
end
if not "0"
  say("ok\t\t- if not \"0\"")
end
if not not "1"
  say("ok\t\t- if not not \"1\"")
end
if not not "123"
  say("ok\t\t- if not not \"123\"")
end
if not not 123
  say("ok\t\t- if not not 123")
end

if "true" eq "true"
  say("ok\t\t- if 'true' == 'true'")
  if "true" eq "false"
    say("fail\t\t- if 'true' == 'false'")
  end
  if 't' eq 't'
    say("ok\t\t- if 't' eq 't'")
  else
    say("fail\t\t- if 't' eq 't'")
  end
else
  say("fail\t\t- if 'true' == 'true'")
end

if "true" eq "false"
  say("fail\t\t- if 'true' eq 'false'")
else
  say("ok\t\t- not 'true' eq 'false'")
end

unless "true" eq "false"
  say("ok\t\t- unless 'true' == 'false'")
else
  say("fail\t\t- unless 'true' == 'false'")
end

unless 't' eq 'f'
  say("ok\t\t- unless 't' eq 'f'")
else
  say("fail\t\t- unless 't' eq 'f'")
end

unless 0 eq 1
  say("ok\t\t- unless 0 eq 1")
elsif 1
  say("fail\t\t- unless-elsif 1")
else
  say("fail\t\t- unless-else")
end

unless not 0
  say("fail\t\t- unless not 0")
elsif not 0
  say("ok\t\t- unless-elsif not 0")
else
  say("fail\t\t- unless-else")
end

if 1 == 1 say("ok\t\t- if 1 == 1"); end
if 0 == 1 say("fail\t\t- if 0 == 1"); end

if 0 or 1
  say("ok\t\t- if 0 or 1")
else
  say("fail\t\t- if 0 or 1")
end

if 1 and 1
  say("ok\t\t- if 1 and 1")
else
  say("fail\t\t- if 1 and 1")
end

if ("any" cmp "any") == 0
  say("ok\t\t- (\"any\" cmp \"any\") == 0")
else
  say("fail\t\t- (\"any\" cmp \"any\") == 0")
end

if ("any" cmp "anx") == 1
  say("ok\t\t- (\"any\" cmp \"anx\") == 1")
else
  say("fail\t\t- (\"any\" cmp \"anx\") == 1")
end

if ("any" cmp "anz") == -1
  say("ok\t\t- (\"any\" cmp \"anz\") == -1")
else
  say("fail\t\t- (\"any\" cmp \"anz\") == -1")
end

if ("123" cmp 123) == 0
  say("ok\t\t- (\"123\" cmp 123) == 0")
else
  say("fail\t\t- (\"123\" cmp 123) == 0")
end
