class MakeFile::Builtin
{
    method info($s) {
        nqp::say($s)
    }

    method warning($s) {
        nqp::say($s)
    }

    method origin($s) {
    }

    method flavor($s) {
    }

    method shell($s) {
        #nqp::shell($s, nqp::cwd, nqp::getenvhash)
    }
}
