Feature: Greet sad paths

  Scenario: Greet spawn fails loud
    * > el spawn greet@nowhere/the-lab
      | unknown node: nowhere |
    * el fails
    * > el spawn greet@lab
      | lab needs a room |
    * el fails
    * no elita node
    * > el spawn greet@lab/the-lab
      | no node, run el node |
    * el fails
