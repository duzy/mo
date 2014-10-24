use config

var $variant = 'debug';

for slice(@ARGS, 1) {
    config::ParseProject($_, $variant).make();
}
