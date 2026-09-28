# Clickless

Keyboard-only clicking for Windows apps, inspired by the Vimium browser extension. Press a hotkey, letter labels appear on everything clickable, type a label to click it.

**Status:** In development — Stage 0 (setup) of 7. See the [design](docs/design.md).

## Why

Existing tools couldn't click into text boxes, struggled with modern apps like VS Code, and couldn't be customised. Clickless fixes those, and pauses itself automatically while games are running.

## Built with

PowerShell 7 · Windows UI Automation · WPF · Pester

## Running the tests

    Invoke-Pester ./tests -Output Detailed
