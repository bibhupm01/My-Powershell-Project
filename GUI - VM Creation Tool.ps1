Clear-Host

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$vm_window = New-Object System.Windows.Forms.Form -Property @{
    Text            = 'VM Creation Tool'
    Font            = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    FormBorderStyle = 'Fixed3D'
    ForeColor       = '#FFFFFF'
    BackColor       = '#1E1E2F'   # modern dark background
    MaximizeBox     = $false
    StartPosition   = 'CenterScreen'
    Width           = 520
    Height          = 250
}

# Title banner
$title_banner = New-Object System.Windows.Forms.Label -Property @{
    Text      = 'VM Creation Tool'
    TextAlign = 'MiddleCenter'
    Font      = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    ForeColor = '#FFFFFF'
    BackColor = '#0078D4'   # bright blue header
    Location  = New-Object System.Drawing.Point(0, 0)
    Size      = New-Object System.Drawing.Size(510, 40)
}

$vm_label = New-Object System.Windows.Forms.Label -Property @{
    Text      = 'Select options:'
    TextAlign = 'MiddleLeft'
    Font      = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    ForeColor = '#00FF88'   # neon green for emphasis
    Location  = New-Object System.Drawing.Point(20, 50)
    Size      = New-Object System.Drawing.Size(510, 25)
}

$vm_MAOX_text = New-Object System.Windows.Forms.Label -Property @{
    Text      = 'MAOX'
    TextAlign = 'MiddleLeft'
    Font      = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    ForeColor = '#FFD700'   # gold accent
    Location  = New-Object System.Drawing.Point(20, 90)
    Size      = New-Object System.Drawing.Size(80, 25)
}

$vm_os_combobox = New-Object System.Windows.Forms.ComboBox -Property @{
    Location      = New-Object System.Drawing.Point(110, 90)
    Size          = New-Object System.Drawing.Size(120, 28)
    DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    Font          = New-Object System.Drawing.Font('Segoe UI', 11)
    BackColor     = '#F0F0F0'
    ForeColor     = '#000000'
}
$vm_os_combobox.Items.AddRange(@('WIN', 'LIN'))
$vm_os_combobox.SelectedIndex = 0

$vm_text = New-Object System.Windows.Forms.TextBox -Property @{
    Location    = New-Object System.Drawing.Point(250, 90)
    Size        = New-Object System.Drawing.Size(230, 28)
    Font        = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    BackColor   = '#F0F0F0'
    ForeColor   = '#000000'
    BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
}

$create_button = New-Object System.Windows.Forms.Button -Property @{
    Text      = 'Create VM'
    Location  = New-Object System.Drawing.Point(190, 150)   # centered better
    Size      = New-Object System.Drawing.Size(140, 40)
    BackColor = '#28A745'   # modern green button
    ForeColor = '#FFFFFF'
    FlatStyle = 'Popup'
    Font      = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
}

# --- VM creation logic unchanged ---
$create_button.Add_Click({
        if ([string]::IsNullOrWhiteSpace($vm_text.Text)) {
            [void][System.Windows.Forms.MessageBox]::Show('VM required field should not be empty.', 'Input Required',
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        $Comp = 'hv.local'
        $User = 'Administrator'
        $Pass = 'Bibhu@7008'
        $secPass = ConvertTo-SecureString $Pass -AsPlainText -Force
        $creds = New-Object System.Management.Automation.PSCredential($User, $secPass)

        $osType = $vm_os_combobox.SelectedItem
        $vmName = $vm_text.Text

        try {
            $vm_window.Hide()

            $session = New-PSSession -ComputerName $Comp -Credential $creds -Authentication Credssp
            Invoke-Command -Session $session -ScriptBlock {
                param($vmName, $osType)

                $vm_full = "MAOX-$osType-$vmName"

                if ($osType -eq 'WIN') {
                    $vm_path = "C:\Virtual Machines\Windows\$vm_full"
                    $iso_path = 'C:\ISO\Windows Server 2022.iso'
                }
                elseif ($osType -eq 'LIN') {
                    $vm_path = "C:\Virtual Machines\Linux\$vm_full"
                    $iso_path = 'C:\ISO\Linux.iso'
                }
                else {
                    throw 'OS type must be WIN or LIN'
                }

                if (-not (Test-Path $vm_path)) { New-Item -ItemType Directory -Path $vm_path | Out-Null }
                $vhdPath = "$vm_path\$vm_full.vhdx"

                New-VHD -Path $vhdPath -Fixed -SizeBytes 40GB -Confirm:$false
                New-VM -Name $vm_full -MemoryStartupBytes 2GB -VHDPath $vhdPath `
                    -SwitchName 'InternalSwitch1' -Path $vm_path -Generation 1 -BootDevice CD
                Add-VMDvdDrive -VMName $vm_full -Path $iso_path
                Start-VM $vm_full
            } -ArgumentList $vmName, $osType

            Remove-PSSession $session

            [void][System.Windows.Forms.MessageBox]::Show("Successfully created VM: $vmName", 'Success',
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

            $vm_window.Show()
        }
        catch {
            [void][System.Windows.Forms.MessageBox]::Show("Error creating VM: $($_.Exception.Message)", 'Error',
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

$vm_window.Controls.AddRange(@($title_banner, $vm_label, $vm_MAOX_text, $vm_os_combobox, $vm_text, $create_button))


[void]$vm_window.ShowDialog()
