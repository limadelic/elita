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

  Scenario: Spawn an unknown agent
    * > el spawn nobody@lab/the-lab
      | unknown agent: nobody |
    * el fails

  @freeq
  @tape:greet
  Scenario: Greet stays quiet on a finished answer
    * > el spawn greet@lab/the-lab
      | greet started |
    * brian> /@+elita/result PRIVMSG #the-lab :@greet hello
    * brian hears nothing more

  @freeq
  @tape:greet
  Scenario: Greet stays quiet on a finished long answer
    * > el spawn greet@lab/the-lab
      | greet started |
    * brian> /@+elita/result BATCH +m1 draft/multiline #the-lab
    * brian> /@batch=m1 PRIVMSG #the-lab :@greet hello
    * brian> /@batch=m1 PRIVMSG #the-lab :how are you
    * brian> /BATCH -m1
    * brian hears nothing more
