# Start-Clickless.ps1
# Entry point for Clickless. For now it proves the project runs and that 
# Windows UI Automation - the accessibility system Clickless is built on -
# can be loaded.

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

# Touch the root of the UI Automation tree (the desktop). If this line
# throws, UI Automation isn't available and nothing else will work.
$null = [System.Windows.Automation.AutomationElement]::RootElement

Write-Output 'Clickless is set up. UI Automation is ready.'


