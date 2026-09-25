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
