# Tests for the clickless entry-point script.

BeforeAll {
    # Path to the script under test, worked out from where this test file lives.
    $Script:ScriptPath = Join-Path $PSScriptRoot '..\src\Start-Clickless.ps1'
}

Describe 'Start-Clickless' {
    It 'reports that UI Automation is ready' {
        $output = & $Script:ScriptPath
        $output | Should -Be 'Clickless is set up. UI Automation is ready.'
    }

    It 'works when run from different folder' {
        Push-Location $env:TEMP
        try {
            $output = & $Script:ScriptPath
            $output | Should -Be 'Clickless is set up. UI Automation is ready.'
        }
        finally {
            Pop-Location
        }
    }
    
}