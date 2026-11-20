---
name: visual-audit
description: Full visual QA pass over an app's UI. Renders every screen, dialog, popup and control in every state and theme, inspects the renders up close against a checklist, fixes each issue once in the shared component, and re-renders to prove it. Use when the user asks for a visual audit, visual QA, UI polish pass, design QA, "check the whole UI", "find the visual bugs", or reports one visual glitch and wants all similar ones found. Works for web, mobile and desktop projects.
---

# Visual audit

Find every visual defect in one pass instead of waiting for the user to report them one at a time. The output is a fixed UI plus a short report with before/after renders.

## 1. Learn how this project renders

Find the cheapest way to get a picture of any screen in any state. In order of preference:

1. **A screenshot hook the project already has**: a `--shot`, `--route` or `--screenshot` flag, a Storybook or component gallery, visual tests. Read the entry point and test folder first.
2. **Web**: start the dev server and drive a headless browser (Playwright, Puppeteer or the browser tool you have). Set the viewport, color scheme and locale per capture.
3. **Mobile**: emulator or simulator screenshots (`adb exec-out screencap -p`, `xcrun simctl io booted screenshot`).
4. **Desktop toolkits (Qt/QML, WPF, Electron, Flutter, ...)**: a small harness that loads a component or page offscreen and grabs the window. If the app has no hook, write a throwaway harness in a scratch folder rather than changing the app.

Always render with **throwaway data**: copy fixtures or a test database into a scratch folder. Never point the audit at the user's real data. Restore any setting you flip (theme, locale, feature flags) when you finish.

**Keep captures from touching the user's screen or data.** A capture that never exits can leave windows or message boxes on the user's desktop, and the next run can trip over it:

- Give every capture its own fresh copy of the data folder. Apps with a single-instance lock or a lock file in the data folder show "already running" dialogs when two runs share one.
- Exit hard right after saving the image (`os._exit`, `process.exit`, `app.exit`), and add a watchdog timer that kills the run after a fixed time no matter what. Flush any output you need before the hard exit.
- Do not trust `timeout` alone: on Windows it often kills only a launcher (such as the `python.exe` shim) while the real process keeps running.
- If you must stop stuck runs, find them by their exact command line (your harness script) and stop only those. Never kill every process of a common name.
- Stopping a background job may leave its loop running. Check that the loop process itself is gone, not only the job.

If every capture comes back blank or identical, check the environment before the code: a locked screen, a minimized window, an animation or fade that has not run yet, or a missing login. Compare against the previous commit to tell an environment problem from a regression.

## 2. Build the inventory

List what has to be looked at before capturing anything:

- **Surfaces**: every route or page, every dialog and sheet, every popup (dropdown lists, menus, tooltips, search results, notification panels), the empty, loading and error variant of each list or table, first-run and onboarding screens.
- **Shared controls**: buttons (each kind and size, icon-only), text fields, text areas, selects, checkboxes, radios, switches, sliders, progress bars, tabs, badges, avatars, pagers, steppers, toasts.
- **States per control**: default, hover, focus, pressed, disabled, selected or checked, error, open (for anything that pops up), busy.
- **Axes**: light and dark theme, LTR and RTL if the app supports it, narrow and wide window or viewport, any "reduced effects" or low-power mode.

A gallery page that puts every control in every state on one screen is the fastest way to cover controls. Build one in the scratch folder if the project has none.

## 3. Capture

- Capture each surface on each axis. Name files `<surface>_<state>_<theme>.png` so they sort together.
- Small things (icons, borders, focus rings, shadows inside circles) need **2x or larger**: raise the device scale factor, or crop and enlarge the region. Most real defects are only a few pixels wide.
- Open each popup, menu and dropdown while capturing. A closed dropdown hides its list's styling.
- Wait out enter animations before grabbing, or turn them off for the capture.
- Open popups through the same signals a user triggers: emit the click or "text edited" signal, or call the open function. Setting a field's text from code usually does not fire the user-edit signal, so a search popup or validation never appears.
- Do not edit the code while the "before" captures are still running. Later captures would already include the fixes. Note the defects, wait for the run to finish, then fix.

## 4. Inspect against the checklist

Look at every capture. For each item, ask whether it holds everywhere, not only on the screen the user mentioned.

**Native or default styling leaking through**
- Popups, dropdown lists, menus, tooltips or dialog backdrops that still use the toolkit's default look (white box, square corners, system border) instead of the app's own surface, radius and shadow.
- Leftover colors from an older palette (hard-coded hex values in overlays, backdrops, badges).
- Placeholder or prompt rows ("Choose...", "Change status...") listed as selectable options instead of shown as the field's prompt text.

**Alignment**
- Icon and label in a button centered as one group, not icon at one edge and text at the other.
- Icon-only buttons truly centered, with no reserved empty text space.
- Dialog close buttons inset like the title, vertically centered on the title, not jammed into the corner.
- Text fields with the same alignment as the page direction. Values that start with digits (dates, amounts, codes) are a common trap: auto-detected direction flips them to the wrong side.
- The same trap in plain labels and list rows: a line that is only digits (a phone number under a name, a date, a count) sits on the wrong side unless its alignment is set explicitly.
- Labels, fields and hints in a form sharing one edge.

**Shape and radius**
- Circles stay circles. Inner shadows or gradients built from straight horizontal and vertical bands draw a visible square inside a round shape.
- Pills (fully rounded ends): straight left/right bands leave hard strips inside the round caps.
- Nested corners: the inner radius equals the outer radius minus the gap between them.
- Bands inside a rounded container (a table header, a total row, a card header or footer): round only the corners that touch the container's edge. A header with all four corners rounded leaves small notches at its bottom ends, where its divider line runs straight to the edge.
- One radius scale across similar components.

**Spacing**
- Space reserved for something that appears only on hover or while dragging (a slider's value bubble, a tooltip, a validation message) leaves a permanent empty gap. Let the transient element float over its neighbors instead.
- Even gaps between a label, its control and its hint across every form.

**Shadow and depth**
- Raised against inset used consistently: fields and tracks pressed in, cards and buttons raised.
- Focus or hover glows that sit outside an inset field make it look raised. Show focus with the field's own border instead.
- Light-side shadows (the highlight half of a soft or neumorphic shadow) look like a white haze on colored surfaces such as an "on" switch track or a primary button.
- Effects drawn over borders: an inner shadow or gradient painted on top of the border fades part of it (often the bottom and right edge of a focus ring). Inset effects belong inside the border.
- Shadows clipped by a parent, or doubled where two components each add one.

**Borders and focus**
- Every focusable control shows focus the same way, and focus is visible in both themes.
- Error state visibly different from focus state.

**Color and contrast**
- Text and icons readable on every surface in both themes, including on tinted badges and selected rows.
- Disabled clearly different from enabled but still legible.
- Selected or highlighted rows in lists use the theme color, not a default blue.

**Text**
- Truncation with an ellipsis where text can overflow, and a tooltip if the full text matters.
- One font family. Mixed fallbacks show up most often in numerals and punctuation.
- Numerals in the locale's digits if the app localizes them.

**RTL (when supported)**
- Directional icons (arrows, chevrons, back) mirrored. Non-directional icons (search, check) not mirrored.
- A popup wider than its anchor opens toward the inside of the page.
- Switch knobs, sliders and progress fill moving in the reading direction.
- Dialogs and popups drawn on a separate overlay layer may not inherit the page's RTL setting. Persian or Arabic text still looks right because it aligns itself, so the only symptom is numeric fields and digit-only labels sitting on the left. Check numbers inside every dialog, and set the direction on the dialog itself if needed.

**Consistency**
- Sibling components that do the same job look the same: every popup, every menu, every badge, every empty state.
- Cards in one row share a height. A row where one card has a second line and the others do not looks ragged; give them all the same lines or stretch them to the tallest.
- Popups and menus keep the same gap from what opened them.

## 5. Fix at the root

- Before editing, find which shared component or style draws the defect, and grep for every other place that uses it. One fix in the shared component beats many local patches.
- Use the project's existing design tokens (colors, radius, spacing, shadow levels). Add a token only if none fits.
- Change behavior only when the user asked. If a visual fix needs a behavior change, such as removing a placeholder row from a list, say so in the report.
- Keep changes reversible and small: one commit per kind of fix, if the project commits per task.

## 6. Verify

- Re-render the same captures after the fixes and compare them with the originals side by side, zoomed in on the fixed area.
- Re-render a broad sample (the gallery plus a few full pages in both themes) to catch regressions the fix caused elsewhere.
- Run the project's tests and any compile or lint step for the UI files.
- If you could not see something (native OS dialogs, print previews, a locked screen), list it as not verified. Do not claim it.

## 7. Report

Keep it short and concrete:

- One line per defect: what was wrong, where (file and component), what changed. Group them by kind (alignment, shape, shadow, color, RTL, consistency).
- The before/after image paths for the important ones.
- What was checked and found fine, in one line.
- What could not be verified, and why.

## Limits

- Native OS dialogs (file pickers, print previews, system prompts) cannot be captured or styled from the app.
- Purely subjective calls ("this color feels off") need the user's eye. Flag them as questions, not defects.
- A full audit takes time. If the user names an area, audit that area across all states and themes instead of the whole app.
