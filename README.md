# visual-audit

An agent skill for a full visual QA pass over an app's UI. Instead of reporting visual glitches one at a time, run the audit once. It renders every screen, dialog, popup and control in every state and theme, checks the renders up close against a checklist, fixes each issue once in the shared component, and re-renders to prove the fix.

It works for web, mobile and desktop projects (Qt/QML, WPF, Electron, Flutter and others). It first finds out how the project can be rendered, then covers:

- screens, dialogs, popups, dropdown lists, menus, tooltips, and empty, loading and error variants
- every control in every state: default, hover, focus, pressed, disabled, checked, error, open
- light and dark themes, LTR and RTL, narrow and wide layouts

The checklist covers default toolkit styling leaking through, icon and text alignment, circles and pills that lose their shape under inner shadows, focus rings and glows, shadows on colored surfaces, borders hidden under effects, contrast, truncation, RTL mirroring, and consistency between similar components.

## Install

The skill is a single `SKILL.md` file in the `visual-audit` folder. Copy that folder into the skills directory of any agent that supports the SKILL.md format, for example:

- user-wide: `~/.claude/skills/visual-audit/`
- one project only: `<project>/.claude/skills/visual-audit/`

## Use

Ask for it in plain words, for example:

> Run a visual audit of the whole app.

> Do a visual QA pass on the settings pages, both themes.

Or call it by name with `/visual-audit`.

## License

MIT
