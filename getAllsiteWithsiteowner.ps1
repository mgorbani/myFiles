
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

#Get All Web Applications
Function global:Get-SPWebApplication($WebAppURL)
{
 if($WebAppURL -eq $null)  #Get All Web Applications
  {
    $Farm = [Microsoft.SharePoint.Administration.SPFarm]::Local
    $websvcs = $farm.Services | where -FilterScript {$_.GetType() -eq [Microsoft.SharePoint.Administration.SPWebService]}
    $WebApps = @()
  foreach ($websvc in $websvcs) {
      foreach ($WebApp in $websvc.WebApplications) {
          $WebApps = $WebApps + $WebApp
      }
  }
  return $WebApps
 }
 else #Get Web Application for given URL
 {
  return [Microsoft.SharePoint.Administration.SPWebApplication]::Lookup($WebAppURL)
 }
}

Function global:Get-SPSite($url)
{
 if($url -ne $null)
    {
    return New-Object Microsoft.SharePoint.SPSite($url)
 }
}
Function global:Get-SPWeb($url)
{
  $site= Get-SPSite($url)
        if($site -ne $null)
            {
               $web=$site.OpenWeb();

            }
    return $web
}

Function GetUserAccessReport($WebAppURL, $SearchUser)
{
 #Get All Site Collections of the WebApp
 $SiteCollections = Get-SPWebApplication($WebAppURL)
 $SiteCollections= $SiteCollections.Sites

 #Write CSV- TAB Separated File) Header
 "URL `t Site Template `t Title `t PermissionType `t Permissions `t UserName"  | out-file UserAccessReport.csv

  #Check Whether the Search Users is a Farm Administrator
  $ca= [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local.Sites[0].RootWeb
        #Get Central Admin
  $AdminSite = Get-SPWeb($ca.URL)
  $AdminGroupName = $AdminSite.AssociatedOwnerGroup.Name

  $FarmAdminGroup = $AdminSite.SiteGroups[$AdminGroupName]

  foreach ($user in $FarmAdminGroup.users)
  {
    if($user.LoginName -eq $SearchUser)
    {
     "$($AdminSite.URL) `t Farm `t $($AdminSite.Title)`t Farm Administrator `t Farm Administrator" | Out-File UserAccessReport.csv -Append
    }
  }

 #Check Web Application Policies
 $WebApp= Get-SPWebApplication $WebAppURL
 foreach ($Policy in $WebApp.Policies)
  {
   #Check if the search users is member of the group
    if($Policy.UserName -eq $SearchUser)
    {
      Write-Host $Policy.UserName
      $PolicyRoles=@()
      foreach($Role in $Policy.PolicyRoleBindings)
        {
          $PolicyRoles+= $Role.Name +";"
        }
      #Write-Host "Permissions: " $PolicyRoles
      "$($WebAppURL) `t Web Application `t $($AdminSite.Title)`t  Web Application Policy `t $($PolicyRoles)" | Out-File UserAccessReport.csv -Append
    }
  }

  #Loop through all site collections
   foreach($Site in $SiteCollections){
    #Check Whether the Search User is a Site Collection Administrator
    Write-Host "Site: Url:" $site.Url
    foreach($SiteCollAdmin in $Site.RootWeb.SiteAdministrators)
    {
      #if($SiteCollAdmin.LoginName -eq $SearchUser){
        "$($Site.RootWeb.Url) `t Site Collections `t $($Site.RootWeb.Title)`t Site Collection Administrator `t Site Collection Administrator `t " | Out-File UserAccessReport.csv -Append
      #}
    }

    #Loop throuh all Sub Sites
    foreach($Web in $Site.AllWebs)
    {     
     getUsersfromweb $Web ""
    } # all web
   }

  }
  function getUsersfromweb($Web, $user){
    if($Web.HasUniqueRoleAssignments -eq $True){
      foreach($WebRoleAssignment in $Web.RoleAssignments ){ 
        foreach($usr in $WebRoleAssignment.Member.Users){
          
          if($usr.isSiteAdmin){
            "$($Web.Url) `t web `t $($Web.Title  ) `t Uniq Assignment `t  $($WebRoleAssignment.Member) `t $($usr) " | Out-File UserAccessReport.csv -Append
          }
          
        }
        write-host
      }
    }else{
      write-host "else: "$Web.Url
      foreach($WebRoleAssignment in $Web.RoleAssignments ){   

        foreach($usr in $WebRoleAssignment.Member.Users){
          Write-Host " hej" $usr.isSiteAdmin
          write-host "owner: " $Web.owner.Name
       
          if($usr.isSiteAdmin){
            "$($Web.Url) `t web `t $($Web.Title  ) `t Direct Permission `t $($WebRoleAssignment.Member) `t $($usr) " | Out-File UserAccessReport.csv -Append
          }
          
        }
        write-host

    }


  }
}
#Call the function to Check User Access
GetUserAccessReport "http://w2k8-wss3sp2" "w2k8-wss3sp2\Administrator"


