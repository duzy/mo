say .name

for class say .name

for class
    say .name
endfor

if class say ->class[0].name

if class
    say ->class[1].name
endif

template MyClass
---{{
class $(.name) : ${for parent yield .name}
{
--- for method
$(.domain):
--- endfor
}
---}}


with ->class[0] yield MyClass
with ->class[1] yield MyClass
with ->class[2] yield MyClass

for class yield MyClass
