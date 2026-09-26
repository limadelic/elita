Feature: Greet Live

  @freeq
  @live
  @tape:bob
  Scenario: Bob answers from his own folder
    * a folder outside the repo with bob.md
    * > el spawn bob@lab/the-lab
      | bob started |
    * brian> /names #the-lab
      | bob=agent |
    * brian> @bob hello
      | :bob!    |
      | @brian   |
      | bob here |

  @freeq
  @live
  @tape:talk2
  Scenario: Greet says hi to bob for brian
    * a folder outside the repo with bob.md
    * > el spawn bob@lab/the-lab
      | bob started |
    * > el spawn greet@lab/the-lab
      | greet started |
    * brian> @greet hello
      | @brian Who am I talking to? |
    * brian> @greet I am brian, say hi to @bob for me
      | :@bob |
    * brian hears
      | :@greet       |
      | bob here      |
      | :@brian       |
      | +elita/result |
    * brian hears nothing more
