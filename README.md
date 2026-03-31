# 🌅 MorningClaude: The Rolling Window Primer

A lightweight, native macOS utility designed to mitigate the [Claude Code rolling window problem](https://usagebar.com/blog/claude-code-weekly-limit-vs-5-hour-lockout).

If you use Anthropic's Claude Code CLI heavily, you know the frustration of the 5-hour rolling session limit. The timer begins the moment you send your first prompt. If you start working at 9:30 AM, your quota won't reset until 2:30 PM—often leaving you rate-limited and locked out right in the middle of your most productive coding blocks.

**MorningClaude mitigates this by acting as an automated window primer.** Set it to wake your Mac and send a lightweight command at 5:00 AM. This automatically triggers your 5-hour rolling window while you are still asleep. By the time you sit down to work, you have plenty of quota for the morning, and your limits will completely reset at 10:00 AM, giving you a completely fresh, unthrottled context window for the rest of the afternoon.

## ✨ Features
* **Beat the Rolling Window:** Prime your 5-hour token limit while you sleep so your resets align with your actual workflow.
* **True Native Wake:** Uses macOS `pmset` to physically wake your machine from sleep 60 seconds before your scheduled task.
* **Background Scheduling:** Uses `launchd` to trigger the automation exactly on time, every time.
* **Batch Processing:** Pass any valid Claude CLI command (e.g., `claude -p 'summarize the recent changes in src/'`) so Claude can do heavy, context-bloating work *before* you even sit down.
* **One-Click Cleanup:** Safely uninstalls all schedules, plist files, and background agents directly from the UI.

---

## 🚀 Installation

### Option 1: Download the Release (Quickest)
1. Download the latest `MorningClaude.zip` from the [Releases](#) page.
2. Unzip it and move `MorningClaude.app` to your `/Applications` folder.
3. **Important Gatekeeper Bypass:** Because this app is unsigned (built open-source to protect developer privacy), macOS will say it is "damaged" if you try to open it directly. Open your terminal and run this command to remove the quarantine flag:
   ```bash
   xattr -cr /Applications/MorningClaude.app