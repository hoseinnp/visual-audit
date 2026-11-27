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
- Captures must not write to the user's real app settings either. Apps that remember the last page, recent items or window size keep them in the registry or a per-user settings file, so test runs can leak test names into the user's app. Point the settings store at the capture's own folder (in Qt: `QSettings.setDefaultFormat(IniFormat)` plus `setPath`). If a smoke run of the built app has no such switch, put back the values it changed afterwards.
- If a licence check, login or feature gate blocks rendering, use the app's dev or test bypass, or add one inside the harness. Do not weaken the gate in the app itself.

If every capture comes back blank or identical, check the environment before the code: a locked screen, a minimized window, an animation or fade that has not run yet, or a missing login. Compare against the previous commit to tell an environment problem from a regression.

- A display that is asleep (user away, monitor off) gives the same symptom without a lock screen. The window is not shown, so frames stop, and animations and timers driven by frames freeze: pages stay at the first, transparent frame of a fade, and data that loads on a timer never arrives. Run one capture that worked earlier with the same harness to confirm it. In Qt, `QSG_RENDER_LOOP=basic` keeps rendering.
- Resizing the window from code while it is not on screen can hang or return an empty image. Set the size before startup instead: the app's saved window size, a launch flag, or the toolkit's default size.

## 2. Build the inventory

List what has to be looked at before capturing anything:

- **Surfaces**: every route or page, every dialog and sheet, every popup (dropdown lists, menus, tooltips, search results, notification panels), the empty, loading and error variant of each list or table, first-run and onboarding screens.
- **Shared controls**: buttons (each kind and size, icon-only), text fields, text areas, selects, checkboxes, radios, switches, sliders, progress bars, tabs, badges, avatars, pagers, steppers, toasts.
- **States per control**: default, hover, focus, pressed, disabled, selected or checked, error, open (for anything that pops up), busy.
- **Axes**: light and dark theme, LTR and RTL if the app supports it, narrow and wide window or viewport, any "reduced effects" or low-power mode.
  - **Text size**: the app's largest text-size setting, or OS font scaling or browser zoom, besides the default.
  - **Window height**: a short window, not only a narrow one. The smallest common laptop screen (such as 1366x768) is the usual case: the window and every dialog must fit with nothing cut off at the bottom.
- **Extreme content**: the dialog with the most buttons or actions, the longest name or label, the largest number or amount, zero rows and very many rows.

A gallery page that puts every control in every state on one screen is the fastest way to cover controls. Build one in the scratch folder if the project has none.

## 3. Capture

- Capture each surface on each axis. Name files `<surface>_<state>_<theme>.png` so they sort together.
- Small things (icons, borders, focus rings, shadows inside circles) need **2x or larger**: raise the device scale factor, or crop and enlarge the region. Most real defects are only a few pixels wide.
- Open each popup, menu and dropdown while capturing. A closed dropdown hides its list's styling.
- Wait out enter animations before grabbing, or turn them off for the capture.
- Open popups through the same signals a user triggers: emit the click or "text edited" signal, or call the open function. Setting a field's text from code usually does not fire the user-edit signal, so a search popup or validation never appears.
- Do not edit the code while the "before" captures are still running. Later captures would already include the fixes. Note the defects, wait for the run to finish, then fix.
- Capture each changed page at several window widths, not only the default: the minimum width, the default, and widths just below and above every breakpoint where columns change.
- A capture that hangs or never saves its image is a finding, not noise. Find what triggers it (which page, which width), then hide parts of the page one at a time from the harness until it stops. That names the component.
- When comparing with an older commit to see where a problem started, check that the older code runs in the same state. If the trigger is a setting the newer code added (a remembered window size, a feature flag), the older commit ignores it and the comparison proves nothing. Reproduce the state another way, such as resizing from the harness.

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
- Two numbers in one cell or label ("date · amount") swap places for the same reason. Put them in separate columns or labels.
- Percent and other signs next to localized digits (Persian or Arabic digits with %) can land on the wrong side of the number. Check them up close, or write the word ("درصد") instead of the sign.
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
- Sizes copied from a sibling can loop. A row that takes its card width from a grid above, while that grid picks its column count from the page width, can widen the page, flip the grid's columns, change the width again and never settle: the page flickers or the app hangs, only at certain window widths. Share the column structure instead of copying a computed width (one grid, or the same column count with fill-width cells and empty filler cells).

**Motion**
- An animation that carries an element to its real state (bar heights in a chart, a panel's final size or position) leaves it wrong whenever the animation stalls or is skipped. Animate decoration only, or make sure the end state is set even if the animation never runs. Check every animated element with animations off (a "reduced effects" mode, if the app has one).

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
- Nothing left over from a sibling view: after switching tabs or views, no header, filter, toolbar or summary that belongs to the previous one is still on screen.
- Buttons, labels and values not clipped or overlapping when a dialog has its most actions or a field its longest value; the layout grows or wraps instead.
- Confirmation dialogs match what they confirm. A normal action (send reminders, export, sync) in the delete dialog's red warning style reads as dangerous. Keep the red style for delete, cancel and other destructive actions.

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
