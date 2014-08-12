model SimpleModel {}
$data = SimpleModel:none

model SomeModel {
    parser {
      <node>
    }

    rule node {
      <name> '=' <value>
    }

    token name {
      <.ident>
    }
}
$data = SomeModel:`filename.data`
$data->child{ ?name }
