Configuration KioskState {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {

        User KioskUser {
            UserName             = "kioskuser"
            Ensure               = "Present"
            Disabled             = $false
            PasswordNeverExpires = $true
            Description          = "Restricted kiosk runtime account"
        }

        Group KioskUserInUsers {
            GroupName        = "Users"
            Ensure           = "Present"
            MembersToInclude = @("kioskuser")
            DependsOn        = "[User]KioskUser"
        }

        Group KioskUserNotAdmin {
            GroupName        = "Administrators"
            Ensure           = "Present"
            MembersToExclude = @("kioskuser")
            DependsOn        = "[User]KioskUser"
        }
    }
}
