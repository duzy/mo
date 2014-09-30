template M
----------
$(.name) $(.id)
.for field;
    $(.name) $(.type)
.end
-------end

for message do {
    say(str M);
}
