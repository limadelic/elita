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

  Scenario: Greet on a node el does not know
    * > el spawn greet@nowhere/the-lab
      | unknown node: nowhere |
    * el fails
