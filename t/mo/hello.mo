say .name

for ->class say .name

for ->class
        say .name
end

if ->class say ->class[0].name

if ->class
       say ->class[1].name
end

template MyClass
--------
class $(.name) : ${for ->parent yield .name}
{
--- for ->method
$(.domain):
--- end
}
---
end

with ->class[0] yield MyClass
with ->class[1] yield MyClass
with ->class[2] yield MyClass

for ->class  yield MyClass

for [.] do
  {
    say .name
    say .extension
    say .nlink
    say .size
    say .mtime
    say .atime
    say .ctime
    say .mode
  }

with <test.xml>
