# comment...

VAR = "test" # comment

FOO$(VAR)BAR = test

$(info test)

foo : bar | baz
	echo $@
bar:
	echo $@
