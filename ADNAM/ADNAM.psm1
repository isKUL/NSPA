function Get-NetUserPrincipal {
    param (
        [string] $domainName,
        [string] $userName
    )
    
    if ( -not ("System.DirectoryServices.AccountManagement.PrincipalContext" -as [type])) 
    { 
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement;
    }

    if ( -not $domainName)
    {
        $domainName = $env:USERDNSDOMAIN;
    }

    if ( -not $userName)
    {
        $userName = $env:USERNAME;
    }

    $context = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain, $domainName);
    $userPrincipal = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity(
                                                                                                $context, 
                                                                                                [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName, 
                                                                                                $userName
                                                                                                );
    return $userPrincipal;
}

function Get-NetGroupPrincipal
{
    param (
        [string] $domainName,
        [Parameter(Mandatory)]
        [string] $groupName
    )

    if ( -not ("System.DirectoryServices.AccountManagement.PrincipalContext" -as [type])) 
    { 
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement;
    }

    if ( -not $domainName)
    {
        $domainName = $env:USERDNSDOMAIN;
    }

    $context = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain, $domainName);
    $groupPrincipal = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity(
                                                                                                 $context, 
                                                                                                 [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName, 
                                                                                                 $groupName
                                                                                                 );
    return $groupPrincipal;
}

Export-ModuleMember -Function Get-NetUserPrincipal, Get-NetGroupPrincipal