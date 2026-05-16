Clear-Host

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -AssemblyName System.Management.Automation

# Windows Form Setup
$Authentication_window = New-Object System.Windows.Forms.Form -Property @{
    Text            = 'Powershell Remote Connection Tool.'
    Font            = New-Object System.Drawing.Font('Segoe UI', 12)
    FormBorderStyle = 'Fixed3D'
    ForeColor       = '#ffffff'
    BackColor       = '#666464'
    MaximizeBox     = $false
    StartPosition   = 'CenterScreen'
    Width           = 548
    Height          = 400
}

$Network_Requirement_Label = New-Object System.Windows.Forms.Label -Property @{
    Text      = 'Connect to LAN or VPN.'
    TextAlign = 'MiddleCenter'
    Font      = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    ForeColor = '#00ff2f'
    BackColor = '#666464' # Match form background
    Location  = New-Object System.Drawing.Point(20, 15)
    Size      = New-Object System.Drawing.Size(490, 20)
}

$VM_Name_Label = New-Object System.Windows.Forms.Label -Property @{
    Text     = 'Windows Machine Name:'
    Location = New-Object System.Drawing.Point(20, 50)
    Font     = New-Object System.Drawing.Font('Segoe UI', 11)
    Size     = New-Object System.Drawing.Size(490, 25)
}

$VM_Name_Text = New-Object System.Windows.Forms.TextBox -Property @{
    Location    = New-Object System.Drawing.Point(20, 80)
    Size        = New-Object System.Drawing.Size(490, 32)
    Font        = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    BackColor   = '#d8d8d8'
    ForeColor   = '#000000' # Black text for contrast
    BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
}

$Username_Name_Label = New-Object System.Windows.Forms.Label -Property @{
    Text     = 'Username:'
    Location = New-Object System.Drawing.Point(20, 125)
    Size     = New-Object System.Drawing.Size(490, 25)
    Font     = New-Object System.Drawing.Font('Segoe UI', 11)
}

$Username_Name_Text = New-Object System.Windows.Forms.TextBox -Property @{
    Location    = New-Object System.Drawing.Point(20, 155)
    Size        = New-Object System.Drawing.Size(490, 32)
    Font        = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    BackColor   = '#d8d8d8'
    ForeColor   = '#000000' # Black text for contrast
    BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
}

$Password_Label = New-Object System.Windows.Forms.Label -Property @{
    Text     = 'Password:'
    Location = New-Object System.Drawing.Point(20, 200)
    Size     = New-Object System.Drawing.Size(490, 25)
    Font     = New-Object System.Drawing.Font('Segoe UI', 11)
}

$Password_Text = New-Object System.Windows.Forms.TextBox -Property @{
    Location              = New-Object System.Drawing.Point(20, 230)
    Size                  = New-Object System.Drawing.Size(490, 32)
    Font                  = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    BackColor             = '#d8d8d8'
    ForeColor             = '#000000' # Black text for contrast
    UseSystemPasswordChar = $true
    BorderStyle           = [System.Windows.Forms.BorderStyle]::FixedSingle
}

$Connect_Button = New-Object System.Windows.Forms.Button -Property @{
    Text      = 'Connect'
    Location  = New-Object System.Drawing.Point(210, 300)
    Size      = New-Object System.Drawing.Size(140, 40)
    BackColor = '#0078D4'
    ForeColor = '#FFFFFF' # White text for contrast
    Font      = New-Object System.Drawing.Font('Segoe UI', 11)
}

$Connect_Button.Add_Click({

        if ([string]::IsNullOrWhiteSpace($VM_Name_Text.Text) -or [string]::IsNullOrWhiteSpace($Username_Name_Text.Text) -or [string]::IsNullOrWhiteSpace($Password_Text.Text)) {
            [void][System.Windows.Forms.MessageBox]::Show('Please enter MachineName, UserName & Password.', 'Input Required', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        $Comp = $VM_Name_Text.Text
        $User = $Username_Name_Text.Text
        $Pass = $Password_Text.Text

        # We escape single quotes in the password to prevent injection errors
        $RemoteScript = @"
        Write-Host "Attempting to connect to: $Comp..." -ForegroundColor Cyan
        try {
            `$secPass = New-Object System.Security.SecureString
            foreach (`$char in '$($Pass.Replace("'", "''"))'.ToCharArray()) {
                `$secPass.AppendChar(`$char)
            }
            `$secPass.MakeReadOnly()
            `$creds = New-Object System.Management.Automation.PSCredential('$User', `$secPass)
            Enter-PSSession -ComputerName '$Comp' -Credential `$creds -Authentication Credssp
        } catch {
            Write-Host "`nCONNECTION ERROR: " -ForegroundColor Red -NoNewline
            Write-Host `$_.Exception.Message -ForegroundColor White
            Read-Host "`nPress Enter to exit"
        }
"@

        $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($RemoteScript))
        
        Start-Process powershell.exe -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-NoProfile', '-EncodedCommand', $Encoded -ErrorAction Stop

    })

$Cancel_Button = New-Object System.Windows.Forms.Button -Property @{
    Text      = 'Cancel'
    Font      = New-Object System.Drawing.Font('Segoe UI', 11)
    Location  = New-Object System.Drawing.Point(370, 300)
    Size      = New-Object System.Drawing.Size(140, 40)
    BackColor = '#cf2c2c'
}
$Cancel_Button.Add_Click({ $Authentication_window.Close() })

$Authentication_window.Controls.AddRange(@($Network_Requirement_Label, $VM_Name_Label, $VM_Name_Text, 
        $Username_Name_Label, $Username_Name_Text, 
        $Password_Label, $Password_Text, $Connect_Button, $Cancel_Button))

[void]$Authentication_window.ShowDialog()
