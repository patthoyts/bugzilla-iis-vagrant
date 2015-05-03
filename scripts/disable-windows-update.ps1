# Disable Windows Update on Vagrant boxes.
$settings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
$settings.NotificationLevel = 1
$settings.Save()
