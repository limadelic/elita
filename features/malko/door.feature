@malko
@live
Feature: Door

  Scenario: First trip into Malkovich
    * > el claude malko
      | ╭─── Claude Code v2.1.208 ─────────────────────────────────────────────────────╮ |
      | │                                                    │ Tips for getting        │ |
      | │                 Welcome back mike!                 │ started                 │ |
      | │                                                    │ Run /init to create a … │ |
      | │                      ▗ ▗   ▖ ▖                     │ ─────────────────────── │ |
      | │                                                    │ What's new              │ |
      | │                        ▘▘ ▝▝                       │ Added screen reader mo… │ |
      | │    Haiku 4.5 · Claude Max · mikemps@gmail.com's    │ Added `vimInsertModeRe… │ |
      | │    Organization                                    │ ─────────────────────── │ |
      | │   ~/dev/self/elita/walter/apps/elita/agents/elita  │ /release-notes for more │ |
      | ╰──────────────────────────────────────────────────────────────────────────────╯ |
    * malko> /exit

  @wip
  Scenario: Tell through the door
    * > el claude malko
      | ▗ ▗   ▖     |
      | ▘▘ ▝▝   |
      | Claude Code |
      | Haiku       |
    * > el claude keeper
      | ▗ ▗   ▖     |
      | ▘▘ ▝▝   |
      | Claude Code |
      | Haiku       |
    * malko> tell keeper open sesame
      | 📢 malko → keeper | open sesame |
    * malko:
      | open sesame |
    * keeper:
      | from malko  |
      | open sesame |
    * malko> /exit
    * keeper> /exit

  @wip
  Scenario: Ask through the door
    * > el claude malko
      | ▗ ▗   ▖     |
      | ▘▘ ▝▝   |
      | Claude Code |
      | Haiku       |
    * > el claude keeper
      | ▗ ▗   ▖     |
      | ▘▘ ▝▝   |
      | Claude Code |
      | Haiku       |
    * malko> keeper what is sesame?
      | 🤔 malko → keeper | what is sesame? |
    * keeper:
      | ✨ keeper | sesame is a magic word |
    * malko:
      | sesame is a magic word |
    * malko> /exit
    * keeper> /exit
