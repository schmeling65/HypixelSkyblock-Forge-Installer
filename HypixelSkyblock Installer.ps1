# Kontrollieren auf eine normale Minecraft Installation
$Minecraft_path = Join-Path $env:APPDATA ".minecraft\launcher_profiles.json"
if (-not Test-Path $Minecraft_path) {
    Write-Host "Minecraft Profil nicht vorhanden. Bitte starte den Minecraft Launcher einmal mit einem angemeldeten Konto."
    exit
}

# Herunterladen und Installieren der aktuellsten Forge-Version 1.21.5
$ForgeInhalt = Invoke-WebRequest -Uri "https://files.minecraftforge.net/net/minecraftforge/forge/index_1.21.5.html"
$ForgeZeilen = $ForgeInhalt.Content -split "`r?`n"

$Regex = '1\.21\.5\s*-\s*55\.\d+\.\d+'

$Erstertreffer = $ForgeZeilen | Where-Object { $_ -match $Regex } | Select-Object -First 1
$Erstertreffer

if ($Erstertreffer -match '55\.\d+\.\d+') {
    $Version = $matches[0]
    
    $Teile = $version -split '\.'

    $Major = $teile[0]
    $Minor = $teile[1]
    $Patch = $teile[2]

    #Write-Host "Major: $Major"
    #Write-Host "Minor: $Minor"
    #Write-Host "Patch: $Patch"
} else {
    Write-Host "Keine gültige Version gefunden."
    exit
}

# Kontrolle auf Forge-Version
# Falls nicht vorhanden, installieren.
$ForgeJar = Join-Path $env:APPDATA ".minecraft\versions\1.21.5-forge-$Major.$Minor.$Patch\1.21.5-forge-$Major.$Minor.$Patch.jar"
if (-not Test-Path $ForgeJar) {
    $ForgeDownloadURL = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.21.5-" + $Major + "." + $Minor + "." + $Patch + "/forge-1.21.5-" + $Major + "." + $Minor + "." + $Patch + "-installer.jar"
    $ForgeDateiName = "forge-1.21.5-" + $Major + "." + $Minor + "." + $Patch + "-installer.jar"

    Invoke-WebRequest -Uri $ForgeDownloadURL -OutFile $ForgeDateiName
    Start-Process ".\$ForgeDateiName"
}

# Setze Pfad der Forge-Installation auf das aktuelle Verzeichniss
$ProfileZeilen = Get-Content(Join-Path $env:APPDATA ".minecraft\launcher_profiles.json")
$ZielIndex = -1
for ($i = 0; $i -lt $ProfileZeilen.Count; $i++) {
    if ($ProfileZeilen[$i] -eq '    "forge" : {') {
        $ZielIndex = $i + 1  # Zeile darunter
        break
    }
}

if ($ZielIndex -ge 0 -and $ZielIndex -lt $ProfileZeilen.Count) {

    if ($ProfileZeilen[$ZielIndex] -match '"[^"]*"\s*:\s*"([^"]+)"') {
        if ($matches[1] -ne Get-Location.Path) {
            $AlteZeile = $ProfileZeilen[$ZielIndex]
            Write-Host "Alte Zeile: $AlteZeile"

            $ProfileZeilen[$ZielIndex] = '      "gameDir" : "' + (Get-Location).Path + '",'
            Set-Content (Join-Path $env:APPDATA ".minecraft\launcher_profiles.json") -Value $ProfileZeilen
            Write-Host "Zeile erfolgreich geändert."
        }
    }
} else {
    Write-Host "Suchbegriff nicht gefunden oder keine Folgezeile vorhanden."
    exit
}

# Erstelle Mods-Ordner, sofern nicht vorhanden.
if (-not Test-Path ((Get-Location).Path + "\mods")) {
    mkdir ".\mods"
}

# Mod-Sektion