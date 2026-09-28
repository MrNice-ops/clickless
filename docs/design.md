# Clickless — Design

**Status:** Draft · **Date:** 2026-09-28

## What it is

Clickless is a keyboard-only way to click things in Windows apps, inspired by the Vimium browser extension. Press a hotkey, short letter labels appear on everything clickable in the current window, type a label, and Clickless acts on that item.

## Why it exists

Hunt-and-Peck, the existing tool that does this, fell short in daily use:

| Problem with Hunt-and-Peck | What Clickless does instead |
| --- | --- |
| Selecting a text box does nothing | Puts the cursor in the text box |
| Unreliable in VS Code and other modern (Electron) apps | Falls back to a real mouse click at the item's position |
| Hotkey can't be changed | Hotkey, hint letters, and label size are set in a settings file |
| Stray input box when nothing is clickable; labels misplaced on scaled / multi-monitor displays | Closes with a message when nothing is found; positions labels correctly with display scaling and on both monitors |
| No way to exclude games | Detects installed games automatically and fully pauses while one is in front |

## Goals

1. **Daily-use tool** — reliable enough to leave running all day.
2. **Maintainable** — small single-purpose parts, each testable on its own.
3. **Open source** — public repo with tests and a README that explains the design.

## Non-goals (for now)

- Scrolling, text selection, or a full "vim mode" for Windows.
- Browser pages — Vimium already covers those.
- Window management (switching / tiling windows).
- Mac or Linux support.

## Technology

- **PowerShell 7** — the whole tool; no compile step, and full access to the same Windows APIs a compiled app would use.
- **Windows UI Automation** (`System.Windows.Automation`) — the accessibility system screen readers use; it lists what's on screen and can act on it.
- **WPF** — draws the label overlay.
- **Small embedded C# snippets** (via `Add-Type`) — register the global hotkey, notice which app is in front, and check for fullscreen apps.
- **Pester** — PowerShell's standard testing framework.

Target machine: Windows 11, PowerShell 7.6, two monitors (2560px wide).

## How it fits together

Seven parts, each with one job, each in its own file:

| Part | Job | Input → Output |
| --- | --- | --- |
| **Finder** | Find clickable items in the active window | window → list of items (name, type, screen position) |
| **Actor** | Act on one item in the right way for its type | item → action performed |
| **Labeler** | Give each item a short, unique label | number of items + hint letters → list of labels |
| **Overlay** | Show labels on screen, read typed letters, close cleanly | items + labels → chosen item (or cancelled) |
| **Listener** | Wait for the hotkey, then run the flow | hotkey press → runs the other parts |
| **Settings** | Load and check the user's preferences | settings file → settings (with safe defaults) |
| **GameGuard** | Decide whether the app in front is a game, and pause Clickless if so | app in front + game folders + settings → "pause" or "active" |

**Everyday flow:** hotkey → Listener → Finder → Labeler → Overlay → (you type) → Actor.

**Game flow:** whenever the app in front changes, GameGuard checks it. If it's a game, the Listener **unregisters the hotkey entirely** (Clickless stops listening to the keyboard) until a non-game app is back in front.

### How GameGuard spots a game

Checked in this order; the first match wins:

1. **Always allow** list (settings) → not a game. For launchers you *do* want Clickless in, e.g. Battle.net or the Riot Client.
2. **Always ignore** list (settings) → game.
3. **Game folders** → game, if the app's program file lives inside one. Folders are found automatically at startup and refreshed daily:
   - **Steam** — every library listed in `steamapps\libraryfolders.vdf`, using its `steamapps\common` folder.
   - **Battle.net, Riot** — install locations from Windows' installed-programs list (registry), matched by publisher (Blizzard Entertainment, Riot Games).
   - **Epic, GOG** — their manifest file / registry entries, if present.
4. **Fullscreen check** (can be turned off in settings) → game, if Windows reports a fullscreen app.
5. Otherwise → not a game.

Because whole folders are ignored rather than individual games, newly installed games are covered with no list to maintain.

**Why fully pause rather than ignore the hotkey:** strict anti-cheat systems (e.g. Riot Vanguard, installed on the target machine) watch for software that listens to keypresses or sends clicks. Stopping all keyboard listening while a game is in front is the safest design. It reduces risk; it can't guarantee how any anti-cheat judges the tool.

### How the Actor chooses an action

Checked in this order; the first one that applies is used:

1. **Button-like** (supports *Invoke*) → press it.
2. **Checkbox / toggle** (supports *Toggle*) → toggle it.
3. **List item / tab** (supports *SelectionItem*) → select it.
4. **Text box** (supports *Value* and isn't read-only) → put the cursor in it.
5. **Anything else** → real mouse click at the item's centre, then move the mouse back.

### Handling problems

- **Nothing clickable found** → brief "No items found" message, no overlay.
- **Item disappears before it's acted on** → skip it quietly; never crash the background tool.
- **Game in front** → Clickless is paused; the hotkey isn't registered, so the keypress goes to the game untouched.
- **A launcher's files can't be read** (moved, uninstalled, format changed) → skip that launcher, log it, keep using the other layers.
- **Esc, or clicking elsewhere** → overlay closes; nothing happens.
- **Bad settings file** → use defaults and say which setting was wrong.
- **Errors** are written to a log file so problems can be diagnosed later.

## Build stages

Each stage ends with something that works.

| Stage | Build |
| --- | --- |
| 0. Setup | Project folder, GitHub repo, first script, first commit |
| 1. "What can it see?" | **Finder**: list clickable items in the active window |
| 2. "Click by number" | **Actor**: pick an item by number and act on it |
| 3. "Labels on screen" | **Labeler** + **Overlay** |
| 4. "Always ready" | **Listener**: background, tray icon, global hotkey |
| 5. "Your settings" | **Settings**: JSON settings file, always-ignore / always-allow lists |
| 5b. "Game detection" | **GameGuard**: find game folders, fullscreen check, full pause |
| 6. "Ship it" | Tests, installer, start-with-Windows, README, release |

## Default settings

| Setting | Default |
| --- | --- |
| Hotkey | `Alt + ;` — uses Windows' standard hotkey registration, so no keyboard hook is needed |
| Hint letters | `sadfjklewcmpgh` (Vimium's defaults) |
| Label size | 12pt |
| Always ignore | *(empty — game folders are detected automatically)* |
| Always allow | *(empty — add launchers you want Clickless in, e.g. `Battle.net.exe`)* |
| Fullscreen counts as a game | On |

## Testing

- **Automated (Pester):** the Labeler and Settings are pure logic and get full tests. The Actor's "which action?" decision is tested with fake items. GameGuard's decision order is tested with fake paths and lists, and the Steam library parser with a sample `libraryfolders.vdf`.
- **Manual checklist:** each stage is checked by hand in File Explorer, Notepad, VS Code, and Settings, on both monitors. Stage 5b adds: hotkey does nothing in World of Warcraft, League of Legends, and a Steam game; works again after switching back; works in the Battle.net launcher once it's on the always-allow list.

## Decisions log

| Decision | Why |
| --- | --- |
| PowerShell, not C# or AutoHotkey | Scriptable with no compile step, and can call the same Windows APIs |
| Mouse-click fallback | Fixes modern apps that don't report proper click actions |
| If PowerShell proves too slow for one part | Rewrite only that part later; don't switch languages up front |
| Detect games by folder, not by name | New games are covered automatically; no list to maintain |
| Fully pause in games, not just ignore the hotkey | Lowest anti-cheat risk (Riot Vanguard is installed) |
| `Alt + ;` as default hotkey | Rarely used by other apps; works with Windows' standard hotkey registration |
