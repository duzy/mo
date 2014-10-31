class MakeFile::Builtin
{
    method info($s) {
        nqp::say($s)
    }

    method shell($s) {
        #nqp::shell($s, nqp::cwd, nqp::getenvhash)
    }
}
