Feature: Greet

  Scenario: Greeeet learns your name
    * > el greet

    * greet> hello
      | who am i talking to |

    * greet> Brian
      | wonderful to meet you |

    * greet> how are you?
      | i am greeeet |

  Scenario: Greet runs in the background
    * > el

    * el> greet &
    * el> ls
      | greet |

    * el> ls //
      | node: elita-cukes |
      | lab (freeq)       |

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

  Scenario: Spawn fails when nick is in use
    * > el spawn brian@lab/the-lab
      | brian: nick in use |
    * el fails
