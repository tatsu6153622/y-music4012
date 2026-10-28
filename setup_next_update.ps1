@'
# setup_next_update.ps1 - YMusic 閾ｪ蜍輔ヱ繝・メ驕ｩ逕ｨ & 繝薙Ν繝画ｧ区・荳諡ｬ繧ｻ繝・ヨ繧｢繝・・繧ｹ繧ｯ繝ｪ繝励ヨ
# iOS (IPA) 縺翫ｈ縺ｳ Windows (MSI) 縺ｮ荳｡譁ｹ縺ｫ蟇ｾ蠢・

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   YMusic 蜈ｨ閾ｪ蜍輔ヱ繝・メ驕ｩ逕ｨ繧帝幕蟋九＠縺ｾ縺・(iOS & Win)   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# --- 1. 荳榊庄隕剖nicode遨ｺ逋ｽ譁・ｭ暦ｼ医ぞ繝ｭ蟷・せ繝壹・繧ｹ遲会ｼ峨・荳諡ｬ繧ｯ繝ｪ繝ｼ繝九Φ繧ｰ ---
Write-Host "`n[1/7] 荳榊庄隕剖nicode遨ｺ逋ｽ譁・ｭ励ｒ繧ｯ繝ｪ繝ｼ繝九Φ繧ｰ荳ｭ..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "build.gradle.kts" -Recurse | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($text -match '[\u2000-\u200F\u202F\u205F\u3000\uFEFF]') {
        $cleaned = [System.Text.RegularExpressions.Regex]::Replace($text, "[\u2000-\u200F\u202F\u205F\u3000\uFEFF]", " ")
        [System.IO.File]::WriteAllText($_.FullName, $cleaned, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "  -> 繧ｯ繝ｪ繝ｼ繝九Φ繧ｰ螳御ｺ・ $($_.Name)" -ForegroundColor Green
    }
}

# --- 2. nativeMain / nativeTest 繧貞ｮ牙・縺ｫ蜃ｦ逅・ｼ・indows JVM繝薙Ν繝牙ｯｾ遲厄ｼ・---
Write-Host "`n[2/7] nativeMain / nativeTest 繧ｽ繝ｼ繧ｹ繧ｻ繝・ヨ蜿ら・繧貞ｮ牙・蛹紋ｸｭ..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "build.gradle.kts" -Recurse | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $mod = $false
    if ($c -match 'val\s+nativeMain\s+by\s+getting') {
        $c = $c -replace 'val\s+nativeMain\s+by\s+getting\s*\{', 'sourceSets.findByName("nativeMain")?.apply {'
        $c = $c -replace 'val\s+nativeMain\s+by\s+getting', 'val nativeMain = sourceSets.findByName("nativeMain")'
        $mod = $true
    }
    if ($c -match 'val\s+nativeTest\s+by\s+getting') {
        $c = $c -replace 'val\s+nativeTest\s+by\s+getting\s*\{', 'sourceSets.findByName("nativeTest")?.apply {'
        $c = $c -replace 'val\s+nativeTest\s+by\s+getting', 'sourceSets.findByName("nativeTest")'
        $mod = $true
    }
    if ($c -match 'sourceSets\.findByName\("nativeTest"\)\s*\{') {
        $c = $c -replace 'sourceSets\.findByName\("nativeTest"\)\s*\{', 'sourceSets.findByName("nativeTest")?.apply {'
        $mod = $true
    }
    if ($mod) {
        Set-Content $_.FullName -Value $c -NoNewline
        Write-Host "  -> 螳牙・蛹門ｮ御ｺ・ $($_.Name)" -ForegroundColor Green
    }
}

# kmpHttp/core 縺ｮ desktopMain / nativeMain 迚ｹ谿贋ｾ晏ｭ倥ｒ隗｣豎ｺ
$kmpCore = "kmpHttp\core\build.gradle.kts"
if (Test-Path $kmpCore) {
    $c = Get-Content $kmpCore -Raw
    $oldDep = 'dependsOn(nativeMain)'
    $newDep = 'val nativeMainSet = sourceSets.findByName("nativeMain"); if (nativeMainSet != null) dependsOn(nativeMainSet)'
    if ($c.Contains($oldDep)) {
        $c = $c.Replace($oldDep, $newDep)
        Set-Content $kmpCore -Value $c -NoNewline
    }
}

# --- 3. engine-js (Node/esbuild) 縺ｮ Windows 蟇ｾ蠢・---
Write-Host "`n[3/7] engine-js 縺ｮ npx.cmd 縺翫ｈ縺ｳ BUNDLE_NAME 繧ｨ繧ｹ繧ｱ繝ｼ繝励ｒ菫ｮ豁｣荳ｭ..." -ForegroundColor Yellow
$engFile = "engine-js\build.gradle.kts"
if (Test-Path $engFile) {
    $c = Get-Content $engFile -Raw
    # npxCmd 螳夂ｾｩ繧定ｿｽ蜉
    if ($c -notmatch 'val npxCmd') {
        $c = $c -replace '(?s)(plugins\s*\{.*?\})', "`$1`n`nval npxCmd: String = if (org.gradle.internal.os.OperatingSystem.current().isWindows) `"npx.cmd`" else `"npx`"`n"
        $c = $c -replace '"npx"', 'npxCmd'
    }
    # Windows逕ｨ繧ｯ繧ｩ繝ｼ繝医お繧ｹ繧ｱ繝ｼ繝・
    $oldDef = 'fun esbuildDefines(bundleName: String, backendVersion: Long) = arrayOf('
    $newDef = @'
val isWin = org.gradle.internal.os.OperatingSystem.current().isWindows
fun esbuildDefines(bundleName: String, backendVersion: Long) = arrayOf(
    if (isWin) "--define:BUNDLE_NAME=\\\"$bundleName\\\"" else "--define:BUNDLE_NAME=\"$bundleName\"",
'@
    if ($c.Contains($oldDef) -and $c -notmatch 'isWin') {
        $c = $c.Replace($oldDef, $newDef)
    }
    Set-Content $engFile -Value $c -NoNewline
    Write-Host "  -> engine-js 菫ｮ豁｣螳御ｺ・ -ForegroundColor Green
}

# --- 4. MSE & QuickJS (MinGW CMake & readlink 繧ｬ繝ｼ繝・ ---
Write-Host "`n[4/7] MSE & QuickJS 縺ｮ Windows (MinGW) 莠呈鋤菫ｮ豁｣荳ｭ..." -ForegroundColor Yellow
# mse/build.gradle.kts
$mseFile = "mse\build.gradle.kts"
if (Test-Path $mseFile) {
    $c = Get-Content $mseFile -Raw
    if ($c -notmatch 'extraArgs') {
        $c = $c -replace '(?s)commandLine\(\s*"cmake",\s*"-S",\s*mseNativeSrc\.absolutePath,\s*"-B",\s*out\.absolutePath,\s*"-DCMAKE_BUILD_TYPE=Release",\s*"-DFFMPEG_ROOT=\$\{ffmpegDesktopPrefix\?\.absolutePath \?: ""\}",\s*"-DPRODUCTION=\$productionC",\s*\)', @'
val isWindows = org.gradle.internal.os.OperatingSystem.current().isWindows
      val extraArgs = if (isWindows) listOf("-G", "Ninja", "-DCMAKE_C_COMPILER=gcc", "-DCMAKE_CXX_COMPILER=g++") else emptyList()
      commandLine(
          listOf(
              "cmake", "-S", mseNativeSrc.absolutePath, "-B", out.absolutePath,
              "-DCMAKE_BUILD_TYPE=Release",
              "-DFFMPEG_ROOT=${ffmpegDesktopPrefix?.absolutePath ?: ""}",
              "-DPRODUCTION=$productionC",
          ) + extraArgs
      )
'@
        Set-Content $mseFile -Value $c -NoNewline
    }
}

# quickjs/build.gradle.kts
$qjsFile = "quickjs\build.gradle.kts"
if (Test-Path $qjsFile) {
    $c = Get-Content $qjsFile -Raw
    if ($c -notmatch 'extraArgs') {
        $c = [System.Text.RegularExpressions.Regex]::Replace($c, '(?s)commandLine\(\s*"cmake",\s*"-S",\s*nativeSrc\.absolutePath,\s*"-B",\s*out\.absolutePath,\s*"-DCMAKE_BUILD_TYPE=Release",\s*"-DCMAKE_OSX_DEPLOYMENT_TARGET=\$macDeploymentTarget",\s*\)', @'
val isWin = org.gradle.internal.os.OperatingSystem.current().isWindows
    val extraArgs = if (isWin) listOf("-G", "Ninja", "-DCMAKE_C_COMPILER=gcc", "-DCMAKE_CXX_COMPILER=g++") else emptyList()
    commandLine(
        listOf(
            "cmake", "-S", nativeSrc.absolutePath, "-B", out.absolutePath,
            "-DCMAKE_BUILD_TYPE=Release",
            "-DCMAKE_OSX_DEPLOYMENT_TARGET=$macDeploymentTarget",
        ) + extraArgs
    )
'@)
        Set-Content $qjsFile -Value $c -NoNewline
    }
}

# quickjs/native/quickjs_web.c (readlink 繧ｬ繝ｼ繝・
$qjsWeb = "quickjs\native\quickjs_web.c"
if (Test-Path $qjsWeb) {
    $c = Get-Content $qjsWeb -Raw
    if ($c -notmatch '#ifndef _WIN32') {
        $c = $c -replace '(\s+n = readlink\("/etc/localtime".*?\}\s*\})', "`n#ifndef _WIN32`$1`n#endif"
        Set-Content $qjsWeb -Value $c -NoNewline
        Write-Host "  -> quickjs_web.c readlink 繧ｬ繝ｼ繝芽ｿｽ蜉螳御ｺ・ -ForegroundColor Green
    }
}

# --- 5. iOS 蜷代￠菫ｮ豁｣・・code 16 / Swift 5 / AssetCatalog・・---
Write-Host "`n[5/7] iOS 蜷代￠繝代ャ繝・ｼ・code 16 & Swift 莠呈鋤諤ｧ・峨ｒ驕ｩ逕ｨ荳ｭ..." -ForegroundColor Yellow
# mse/native/mse_vt_dec.m
$mseVt = "mse\native\mse_vt_dec.m"
if (Test-Path $mseVt) {
    $c = Get-Content $mseVt -Raw
    if ($c -notmatch 'TargetConditionals\.h') {
        $c = "#import <TargetConditionals.h>`n" + $c
    }
    if ($c -match 'VTRegisterSupplementalVideoDecoderIfAvailable' -and $c -notmatch '#if TARGET_OS_OSX') {
        $c = $c -replace '(?s)(if \(@available\(macOS 11\.0, \*\)\) \{.*?VTRegisterSupplementalVideoDecoderIfAvailable.*?\})', "#if TARGET_OS_OSX`n`$1`n#endif"
    }
    Set-Content $mseVt -Value $c -NoNewline
}

# iosApp/iosApp/IosPip.swift 譛ｫ蟆ｾ繧ｫ繝ｳ繝槫炎髯､
$pipSwift = "iosApp\iosApp\IosPip.swift"
if (Test-Path $pipSwift) {
    $c = Get-Content $pipSwift -Raw
    $c = $c -replace ',\s*\n\s*\)', "`n    )"
    Set-Content $pipSwift -Value $c -NoNewline
}

# iosApp/gen_xcodeproj.rb
$genProj = "iosApp\gen_xcodeproj.rb"
if (Test-Path $genProj) {
    $c = Get-Content $genProj -Raw
    $c = $c -replace "app_target\.resources_build_phase\.add_file_reference\(assets_ref\)", "# app_target.resources_build_phase.add_file_reference(assets_ref)"
    $c = $c -replace "config\.build_settings\['ASSETCATALOG_COMPILER_APPICON_NAME'\]", "# config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME']"
    Set-Content $genProj -Value $c -NoNewline
}

# Deployment targets
@("mse\build.gradle.kts", "quickjs\build.gradle.kts") | ForEach-Object {
    if (Test-Path $_) {
        $c = Get-Content $_ -Raw
        $c = $c -replace 'IPHONEOS_DEPLOYMENT_TARGET=12\.0', 'IPHONEOS_DEPLOYMENT_TARGET=15.0'
        $c = $c -replace '"-w"', '"-Wno-unguarded-availability-new"'
        Set-Content $_ -Value $c -NoNewline
    }
}

# --- 6. GitHub Actions 繝ｯ繝ｼ繧ｯ繝輔Ο繝ｼ縺ｮ驟咲ｽｮ繝ｻ遒ｺ隱・---
Write-Host "`n[6/7] GitHub Actions 繝ｯ繝ｼ繧ｯ繝輔Ο繝ｼ・・uild-ios.yml & build-windows.yml・峨ｒ遒ｺ隱堺ｸｭ..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path ".github\workflows" | Out-Null
Write-Host "  -> 繝ｯ繝ｼ繧ｯ繝輔Ο繝ｼ繝輔か繝ｫ繝遒ｺ隱榊ｮ御ｺ・ -ForegroundColor Green

# --- 7. 螳御ｺ・Γ繝・そ繝ｼ繧ｸ ---
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "   縺吶∋縺ｦ縺ｮ閾ｪ蜍輔ヱ繝・メ驕ｩ逕ｨ縺梧ｭ｣蟶ｸ縺ｫ螳御ｺ・＠縺ｾ縺励◆・・  " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "縺ゅ→縺ｯ莉･荳九・繧ｳ繝槭Φ繝峨ｒ螳溯｡後☆繧九□縺代〒縲∬・蜍輔〒繝薙Ν繝峨＆繧後∪縺・`n" -ForegroundColor White
Write-Host "  git add ." -ForegroundColor Yellow
Write-Host "  git commit -m `"Apply full cross-platform build patches`"" -ForegroundColor Yellow
Write-Host "  git push" -ForegroundColor Yellow
Write-Host "`nGitHub縺ｮActions繧ｿ繝悶°繧・IPA・・Pad・峨→ MSI・・indows・峨′繝繧ｦ繝ｳ繝ｭ繝ｼ繝峨〒縺阪∪縺呻ｼ・ -ForegroundColor Cyan
'@ | Set-Content -Path "setup_next_update.ps1" -Encoding utf8

# Git縺ｫ逋ｻ骭ｲ縺励※縺翫￥
git add setup_next_update.ps1
git commit -m "Add full cross-platform auto-patch setup script"
git push