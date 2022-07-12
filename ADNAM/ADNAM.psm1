function NetUserPrincipal {
    param (
        [Parameter(Position=0)]
        [string] $domainName,
        [Parameter(Position=1)]
        [string] $userName
    )
    
    if ( -not ("System.DirectoryServices.AccountManagement.PrincipalContext" -as [type])) 
    { 
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
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
    return $userPrincipal
}

Export-ModuleMember -Function NetUserPrincipal