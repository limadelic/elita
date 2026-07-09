Feature: Shipped cache

  @tape:el @tape_on_miss:live
  Scenario: Shipped cassette with fallthrough to live on miss
    * > el

    * el> hello
      | hello from cassette |

    * el> unknown
      | response from stubbed server |
