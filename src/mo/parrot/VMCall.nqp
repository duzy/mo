class VMCall {
    our sub readdir($path) {
        pir::new__PS('OS').readdir($path)
    }
}
