# `zago` Documentation

This directory holds the detailed user and language documentation. The root [README](../README.md) is the short project entry point.

## Guides

- [Editor LOGO command language](logo.md): command prompt behavior, language vocabulary, drawing commands, procedures, data primitives, and examples.
- [Editor LOGO text transliteration](logo_text_transliteration.md): proposed ICU String Transform primitive for text/script conversion.
- [Command & Editor LOGO Architecture](command_architecture.md): unified division of responsibilities between Editor `Command` and `LogoEngine`.
- [Editor basics](editor.md): common editing keys and basic editor behavior.
- [Search](search.md): active search query, repeated next/previous navigation, highlighting, and regex search rules.
- [Heading navigation & outline](heading_navigation.md): document heading parsing, next/previous heading navigation, and outline picker behavior.
- [Mark, selection, and clipboard behavior](mark.md): text selection and canvas block mark rules.
- [Configuration](configuration.md): `.zagorc`, key bindings, startup Editor LOGO code, command ids, Nano syntax file loading, and single-level embedded code block highlighting.
- [Editor modes & layout](modes.md): Text Editing Mode, Canvas Mode, and Table Mode.
- [Directory mode & permissions](directory_mode.md): DirectoryBuffer architecture, command filtering matrix, and Editor LOGO execution restrictions.
- [Diagram snippets & menu rules](diagram_snippets.md): trigger conditions, code block context detection, filtering rules, and Editor LOGO `DIAGRAM` command usage.
- [Homebrew tap](homebrew_tap.md): personal tap layout, Formula template, release checksum workflow, and user install commands.
- [Spell Checker Architecture & Plan](spell_checker.md): multi-language design, platform engines (Windows COM API, Hunspell, macOS NSSpellChecker), Markdown context filtering, and `.zagorc` language directives.
- [Release & preview builds](release.md): source install, smoke tests, release checklist, tester bug report template, and known preview limitations.
