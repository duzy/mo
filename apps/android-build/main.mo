use build

var $path    = (1 < +@ARGS) ? @ARGS[1] : cwd;
var $variant = 'debug';

for slice(@ARGS, 1) {
    build::Add($_, $variant).make();
}
