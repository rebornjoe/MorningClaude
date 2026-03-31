import SwiftUI
import Foundation

struct DayInfo: Identifiable {
    let id: Int
    let name: String
    let pmsetChar: String
}

struct ContentView: View {
    @State private var statusMessage: String = "Ready to schedule."
    @State private var selectedTime: Date = defaultWakeTime()
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5] // Default to Mon-Fri
    @State private var customCommand: String = "hi"

    let daysOfWeek = [
        DayInfo(id: 1, name: "M", pmsetChar: "M"),
        DayInfo(id: 2, name: "T", pmsetChar: "T"),
        DayInfo(id: 3, name: "W", pmsetChar: "W"),
        DayInfo(id: 4, name: "T", pmsetChar: "R"),
        DayInfo(id: 5, name: "F", pmsetChar: "F"),
        DayInfo(id: 6, name: "S", pmsetChar: "S"),
        DayInfo(id: 7, name: "S", pmsetChar: "U")
    ]

    static func defaultWakeTime() -> Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Morning, Claude")
            .font(.title2)
            .fontWeight(.bold)

            // Time Selector
            DatePicker("Launch Time:", selection: $selectedTime, displayedComponents: .hourAndMinute)
            .datePickerStyle(.compact)
            .frame(maxWidth: 250)

            // Day Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Run on days:")
                .font(.subheadline)
                .foregroundColor(.secondary)

                HStack {
                    ForEach(daysOfWeek) { day in
                        Text(day.name)
                        .frame(width: 30, height: 30)
                        .background(selectedDays.contains(day.id) ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .onTapGesture {
                            if selectedDays.contains(day.id) {
                                selectedDays.remove(day.id)
                            } else {
                                selectedDays.insert(day.id)
                            }
                        }
                    }
                }
            }

            // Custom Command Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Claude Command:")
                .font(.subheadline)
                .foregroundColor(.secondary)

                HStack {
                    TextField("Command to send upon wake", text: $customCommand)
                    .textFieldStyle(.roundedBorder)

                    Button("Default") {
                        customCommand = "hi"
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: 350)
            .padding(.top, 5)

            // Action Buttons
            HStack(spacing: 15) {
                Button(action: {
                    testScript()
                }) {
                    Text("Test Script")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .disabled(customCommand.isEmpty)

                Button(action: {
                    setupAutomation()
                }) {
                    Text("Install Schedule")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedDays.isEmpty || customCommand.isEmpty)
            }
            .padding(.top, 10)

            // Cancel Button
            Button(action: {
                cancelAutomation()
            }) {
                Text("Cancel Schedule & Uninstall")
                .foregroundColor(.red)
                .font(.callout)
            }
            .buttonStyle(.plain)
            .padding(.top, 5)

            Text(statusMessage)
            .font(.footnote)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .frame(height: 40)
        }
        .padding(30)
        .frame(width: 450, height: 480) // Slightly taller to fit the new button
    }

    // Helper function to safely escape strings for bash and AppleScript
    func buildAppleScript() -> String {
        let bashEscaped = "'" + customCommand.replacingOccurrences(of: "'", with: "'\\''") + "'"
        let appleScriptSafe = bashEscaped
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")

        // 1. Source the zsh profile so it knows where Claude/Node is installed.
        // 2. Run the Claude command.
        // 3. Keep the window open afterward by launching an interactive zsh shell.
        let shellCommand = "source ~/.zshrc 2>/dev/null; claude -p \(appleScriptSafe); exec zsh"

        return """
               tell application "Terminal"
                   activate
                   do script "\(shellCommand)"
               end tell
               """
    }
    func testScript() {
        statusMessage = "Running test..."
        let scriptSource = buildAppleScript()
        var errorInfo: NSDictionary?

        if let appleScript = NSAppleScript(source: scriptSource) {
            appleScript.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                statusMessage = "Test failed. Check permissions.\n\(error)"
            } else {
                statusMessage = "Test executed successfully."
            }
        } else {
            statusMessage = "Failed to compile AppleScript."
        }
    }

    func setupAutomation() {
        statusMessage = "Setting up..."

        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: selectedTime)
        let targetMinute = calendar.component(.minute, from: selectedTime)

        guard let wakeTime = calendar.date(byAdding: .minute, value: -1, to: selectedTime) else {
            statusMessage = "Error calculating wake time."
            return
        }
        let wakeHour = calendar.component(.hour, from: wakeTime)
        let wakeMinute = calendar.component(.minute, from: wakeTime)
        let formattedWakeTime = String(format: "%02d:%02d:00", wakeHour, wakeMinute)

        var pmsetDaysString = ""
        for day in daysOfWeek {
            if selectedDays.contains(day.id) {
                pmsetDaysString.append(day.pmsetChar)
            }
        }

        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let scriptsDir = homeDir.appendingPathComponent("Library/Scripts")
        let launchAgentsDir = homeDir.appendingPathComponent("Library/LaunchAgents")

        // 1. pmset schedule
        let pmsetScript = "do shell script \"pmset repeat wake \(pmsetDaysString) \(formattedWakeTime)\" with administrator privileges"
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: pmsetScript) {
            appleScript.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                statusMessage = "Error setting wake schedule: \(error)"
                return
            }
        }

        // 2. Write the dynamic AppleScript to file
        let claudeAppleScriptContent = buildAppleScript()
        let scriptURL = scriptsDir.appendingPathComponent("morning_claude.scpt")

        do {
            try fileManager.createDirectory(at: scriptsDir, withIntermediateDirectories: true, attributes: nil)
            try claudeAppleScriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            statusMessage = "Failed to save automation script."
            return
        }

        // 3. Create LaunchAgent XML
        var intervalsXML = ""
        for day in selectedDays {
            intervalsXML += """
                                    <dict>
                                        <key>Hour</key>
                                        <integer>\(targetHour)</integer>
                                        <key>Minute</key>
                                        <integer>\(targetMinute)</integer>
                                        <key>Weekday</key>
                                        <integer>\(day)</integer>
                                    </dict>
                            """
        }

        let plistContent = """
                           <?xml version="1.0" encoding="UTF-8"?>
                           <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                           <plist version="1.0">
                           <dict>
                               <key>Label</key>
                               <string>com.user.morningclaude</string>
                               <key>ProgramArguments</key>
                               <array>
                                   <string>/usr/bin/osascript</string>
                                   <string>\(scriptURL.path)</string>
                               </array>
                               <key>StartCalendarInterval</key>
                               <array>
                           \(intervalsXML)
                               </array>
                           </dict>
                           </plist>
                           """

        let plistURL = launchAgentsDir.appendingPathComponent("com.user.morningclaude.plist")

        do {
            try fileManager.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true, attributes: nil)
            try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
        } catch {
            statusMessage = "Failed to save LaunchAgent."
            return
        }

        // 4. Load LaunchAgent
        let unloadProcess = Process()
        unloadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        unloadProcess.arguments = ["unload", plistURL.path]
        try? unloadProcess.run()
        unloadProcess.waitUntilExit()

        let loadProcess = Process()
        loadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        loadProcess.arguments = ["load", plistURL.path]

        do {
            try loadProcess.run()
            statusMessage = "Success! Waking at \(formattedWakeTime) and launching at \(String(format: "%02d:%02d", targetHour, targetMinute))."
        } catch {
            statusMessage = "Failed to load the scheduled task into launchd."
        }
    }

    // NEW: Cancel and Cleanup Function
    func cancelAutomation() {
        statusMessage = "Canceling schedule and cleaning up..."

        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let scriptsDir = homeDir.appendingPathComponent("Library/Scripts")
        let launchAgentsDir = homeDir.appendingPathComponent("Library/LaunchAgents")

        let scriptURL = scriptsDir.appendingPathComponent("morning_claude.scpt")
        let plistURL = launchAgentsDir.appendingPathComponent("com.user.morningclaude.plist")

        // 1. Cancel the pmset wake schedule (requires admin password)
        let pmsetScript = "do shell script \"pmset repeat cancel\" with administrator privileges"
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: pmsetScript) {
            appleScript.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                statusMessage = "Error canceling wake schedule: \(error)"
                return
            }
        }

        // 2. Unload the LaunchAgent if it exists
        if fileManager.fileExists(atPath: plistURL.path) {
            let unloadProcess = Process()
            unloadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            unloadProcess.arguments = ["unload", plistURL.path]
            try? unloadProcess.run()
            unloadProcess.waitUntilExit()

            // Delete the plist file
            try? fileManager.removeItem(at: plistURL)
        }

        // 3. Delete the AppleScript file
        if fileManager.fileExists(atPath: scriptURL.path) {
            try? fileManager.removeItem(at: scriptURL)
        }

        statusMessage = "Schedule successfully canceled and files removed."
    }
}