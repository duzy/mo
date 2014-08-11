for ->[test/text.txt]{ .IFREG } do
  {
    $ha = <-(.path)
    $ascii = <($ha 1024)

    $hb = <-[.path]
    $block = <[$hb 1024]
  }
