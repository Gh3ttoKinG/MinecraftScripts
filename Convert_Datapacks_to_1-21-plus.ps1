<#
  https://www.planetminecraft.com/forums/minecraft/datapacks/how-can-i-get-my-data-packs-to-work-in-1-21-685861/
  Through this forum post I found out that the namespaces within the datapacks have been changed from plural to singular.
  To confirm this I checked the following links in the Minecraft Wiki:
  https://minecraft.wiki/w/Java_Edition_1.21#Command_format_2
  https://minecraft.wiki/w/Data_pack#History
  This is very stupid and annoying, so I worte myself a simple Powershell-Script for this.

  Put it into the datapacks folder and execute it.
  Alternatively you can copy everything except the last two lines into the Powershell Console and type in the following commands
  RenameMCFolders "Full-Path-to-datapacks-folder"
  RenameMCzipFolders "Full-Path-to-datapacks-folder"
#>
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'

$NameChanges = @(
"\tags\items",
"\tags\blocks",
"\tags\entity_types",
"\tags\fluids",
"\tags\game_events",
"\tags\functions",
"\structures",
"\advancements",
"\recipes",
"\loot_tables",
"\predicates",
"\item_modifiers",
"\functions"
)

function RenameMCFolders {
  param(
      $folderPath = $pwd.Path
  )
  $folders = GCI -LiteralPath $folderpath -Directory -Depth 10 | Sort -Property @{ Expression = {$_.FullName.Split('\').Count} } -Desc
  Foreach ($folder in $folders) {
    ForEach ($NameChange in $NameChanges) {
      If ($folder.FullName -like ("*" + $NameChange)) {
        Write-Host ('Renaming "' + $folder.FullName + '"')
        Write-Host ('to "' + $folder.Name.Substring(0, $folder.Name.Length - 1) + '"')
        Rename-Item -LiteralPath $folder $folder.Name.Substring(0, $folder.Name.Length - 1)
        break
      }
   }
  }
}

function RenameMCzipFolders {
  param(
      $folderPath = $pwd.Path
  )
  $folderPath = GI -LiteralPath $folderPath
  If ($folderPath) {
    $tempPath = ($folderPath.FullName + '\' + 'temp_' + (Get-Date).ToString("yyyy-MM-dd_hh-mm-ss")) + '\'
    $zipfiles = GCI -LiteralPath $folderPath -Filter "*.zip"
    Foreach ($zipfile in $zipfiles) {
      $zip = [IO.Compression.ZipFile]::Open( $zipfile, 'Update' )
      $zipEntries = $zip.Entries | Where {$_.FullName.Substring($_.FullName.Length-1) -eq '/'}
      $Extract = $False
      If ($False -eq $Extract) {
        ForEach ($zipEntry in $zipEntries) {
          If ($True -eq $Extract) { break }
          Write-Host $Extract
          If ($False -eq $Extract) {
            ForEach ($NameChange in $NameChanges) {
              If ($zipEntry.FullName -like ("*" + $NameChange.replace("\","/") + "/")) {
                Write-Host ('Found "' + $NameChange + '"')
                Write-Host ('in "' + $zipEntry.FullName + '"!')
                $Extract = $True
                break
              }
            }
          }
        }
      }
      $zip.Dispose()
      If ($True -eq $Extract) { 
        [IO.Compression.ZipFile]::ExtractToDirectory($zipfile, ($tempPath + $zipfile.BaseName))
        RenameMCFolders ($tempPath + $zipfile.BaseName)
        Rename-Item $zipfile ($zipfile.Name + '.bak')
        [IO.Compression.ZipFile]::CreateFromDirectory(($tempPath + $zipfile.BaseName), ($zipfile.BaseName + ".zip"))
        Remove-Item -LiteralPath ($tempPath + $zipfile.BaseName) -Recurse -Force -Confirm:$False
      }
    }
    Remove-Item -LiteralPath $tempPath -Recurse -Force -Confirm:$False
  } Else {
    Write-Host ("Folder doesn't exist!")
  }
}

RenameMCFolders
RenameMCzipFolders
