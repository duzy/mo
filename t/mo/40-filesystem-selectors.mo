# Filesystem selectors
$subset = ->"test"[ "1.txt", "2.txt", "3.txt" ]{ .IFREG }
$subset = ->["dir/1.txt", "dir/2.txt", "dir/3.txt"]{ .IFREG }
