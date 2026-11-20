# visual-audit

An agent skill for a full visual QA pass over an app's UI. Instead of reporting visual glitches one at a time, run the audit once. It renders every screen, dialog, popup and control in every state and theme, checks the renders up close against a checklist, fixes each issue once in the shared component, and re-renders to prove the fix.

It works for web, mobile and desktop projects (Qt/QML, WPF, Electron, Flutter and others). It first finds out how the project can be rendered, then covers:

- screens, dialogs, popups, dropdown lists, menus, tooltips, and empty, loading and error variants
- every control in every state: default, hover, focus, pressed, disabled, checked, error, open
- light and dark themes, LTR and RTL, narrow and wide layouts

The checklist covers default toolkit styling leaking through, icon and text alignment, circles and pills that lose their shape under inner shadows, focus rings and glows, shadows on colored surfaces, borders hidden under effects, contrast, truncation, RTL mirroring, and consistency between similar components.

## Install

### As a plugin (recommended)

Inside a session, run:

```
/plugin marketplace add hoseinnp/visual-audit
/plugin install visual-audit@visual-audit
```

Updates come with `/plugin marketplace update visual-audit`.

### With the install script

Copies `SKILL.md` into your user skills folder (`~/.claude/skills/visual-audit/`).

macOS / Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/hoseinnp/visual-audit/main/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/hoseinnp/visual-audit/main/install.ps1 | iex
```

Options: `--project` / `-Project` installs into `.claude/skills` of the current folder, `--dir <path>` / `-Dir <path>` into any folder, and `--uninstall` / `-Uninstall` removes it. To pass options, download the script first (`sh install.sh --project`, `.\install.ps1 -Project`).

### By hand

Copy the `skills/visual-audit` folder into `~/.claude/skills/` (all projects) or `<project>/.claude/skills/` (one project).

## Use

Ask for it in plain words, for example:

> Run a visual audit of the whole app.

> Do a visual QA pass on the settings pages, both themes.

Or call it by name with `/visual-audit` (as a plugin: `/visual-audit:visual-audit`).

## License

MIT
