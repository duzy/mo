use build

var $variant = 'debug';

for slice(@ARGS, 1) {
    build::Add($_, $variant).make();
}
