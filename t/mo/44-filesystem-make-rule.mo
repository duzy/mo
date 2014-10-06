say('1..22');

var $node = <'t/mo/test/temp.txt'>;

def touch($node, @depends) {
    if system('touch '~$node.PATH) == 0 {
        say('ok - built '~$node.PATH)
    }
}

't/mo/test/temp.txt' : 't/mo/test/temp_dep1.txt'
{
    if system('touch '~$_.PATH) == 0 {
        say('ok - built '~$_.PATH)
    }
}

't/mo/test/temp_dep1.txt' : 't/mo/test/temp_dep2.txt'
{
    if system('touch '~$_.PATH) == 0 {
        say('ok - built '~$_.PATH)
    }
}

't/mo/test/temp_dep2.txt' : 't/mo/test/temp_dep3.txt'
{
    if system('touch '~$_.PATH) == 0 {
        say('ok - built '~$_.PATH)
    }
}

't/mo/test/temp_dep3.txt' :
{
    if system('touch '~$_.PATH) == 0 {
        say('ok - built '~$_.PATH)
    }
}

var $dep1 = <'t/mo/test/temp_dep1.txt'>;
var $dep2 = <'t/mo/test/temp_dep2.txt'>;
var $dep3 = <'t/mo/test/temp_dep3.txt'>;

if +$node.depends() == 1 { say('ok - 1 prerequisite for node') }
if +$dep1.depends() == 1 { say('ok - 1 prerequisite for dep1') }
if +$dep2.depends() == 1 { say('ok - 1 prerequisite for dep2') }
if isnull($dep3.depends()) { say('ok - no prerequisite for dep3') }

if $node.exists() { system('rm -f ' ~ $node.PATH) }
if $dep1.exists() { system('rm -f ' ~ $dep1.PATH) }
if $dep2.exists() { system('rm -f ' ~ $dep2.PATH) }
if $dep3.exists() { system('rm -f ' ~ $dep3.PATH) }

if $node.make() == 4 { say('ok - 4 targets made') }
if $node.exists() { say('ok - exists ' ~ $node.PATH) }
if $dep1.exists() { say('ok - exists ' ~ $dep1.PATH) }
if $dep2.exists() { say('ok - exists ' ~ $dep2.PATH) }
if $dep3.exists() { say('ok - exists ' ~ $dep3.PATH) }

system('sleep 1 ; touch '~$dep2.PATH);
if $node.make() == 3 { say('ok - 3 targets remade') }

system('sleep 1 ; touch '~$dep1.PATH);
if $node.make() == 2 { say('ok - 2 targets remade') }

if $node.exists() { say('ok - exists ' ~ $node.PATH); system('rm -f ' ~ $node.PATH) }
if $dep1.exists() { say('ok - exists ' ~ $dep1.PATH); system('rm -f ' ~ $dep1.PATH) }
if $dep2.exists() { say('ok - exists ' ~ $dep2.PATH); system('rm -f ' ~ $dep2.PATH) }
if $dep3.exists() { say('ok - exists ' ~ $dep3.PATH); system('rm -f ' ~ $dep3.PATH) }
