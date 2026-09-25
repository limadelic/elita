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

  @freeq
  Scenario: Greet joins the lab
    * > el spawn greet@lab/the-lab
      | greet started |

    * brian> /names #the-lab
      | greet=agent |

    * brian> /whois greet
      | actor_class=agent |

  @freeq
  Scenario: Bob joins the lab from his own folder
    * a folder outside the repo with bob.md
    * > el spawn bob@lab/the-lab
      | bob started |
    * brian> /names #the-lab
      | bob=agent |
