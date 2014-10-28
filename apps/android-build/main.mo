use config

var $variant = 'debug';
var @projects = list();

for slice(@ARGS, 1) {
    var $project = config::ParseProject($_, $variant);
    @projects.push($project);
    $project.make();
}
