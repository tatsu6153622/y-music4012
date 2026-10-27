# apply_ios_patches.ps1 - YMusic iOSビルド用修正一括適用スクリプト

Write-Host "=== YMusic iOS パッチ適用を開始します ===" -ForegroundColor Cyan

# 1. mse/build.gradle.kts の修正
$mseGradle = "mse\build.gradle.kts"
if (Test-Path $mseGradle) {
    (Get-Content $mseGradle -Raw) -replace 'IPHONEOS_DEPLOYMENT_TARGET=12\.0', 'IPHONEOS_DEPLOYMENT_TARGET=15.0' `
                                  -replace '"-w"', '"-Wno-unguarded-availability-new"' | Set-Content $mseGradle -NoNewline
    Write-Host "[OK] $mseGradle を更新しました" -ForegroundColor Green
}

# 2. quickjs/build.gradle.kts の修正
$qjsGradle = "quickjs\build.gradle.kts"
if (Test-Path $qjsGradle) {
    (Get-Content $qjsGradle -Raw) -replace 'IPHONEOS_DEPLOYMENT_TARGET=12\.0', 'IPHONEOS_DEPLOYMENT_TARGET=15.0' | Set-Content $qjsGradle -NoNewline
    Write-Host "[OK] $qjsGradle を更新しました" -ForegroundColor Green
}

# 3. mse/native/mse_vt_dec.m の修正 (TargetConditionals.h & macOS分岐)
$mseVtDec = "mse\native\mse_vt_dec.m"
if (Test-Path $mseVtDec) {
    $content = Get-Content $mseVtDec -Raw
    if ($content -notmatch 'TargetConditionals\.h') {
        $content = "#import <TargetConditionals.h>`n" + $content
    }
    if ($content -match 'VTRegisterSupplementalVideoDecoderIfAvailable' -and $content -notmatch '#if TARGET_OS_OSX') {
        $content = $content -replace '(?s)(if \(@available\(macOS 11\.0, \*\)\) \{.*?VTRegisterSupplementalVideoDecoderIfAvailable.*?\})', "#if TARGET_OS_OSX`n`$1`n#endif"
    }
    Set-Content $mseVtDec -Value $content -NoNewline
    Write-Host "[OK] $mseVtDec を更新しました" -ForegroundColor Green
}

# 4. iosApp/iosApp/IosPip.swift の修正 (Swift 5末尾カンマ削除)
$pipSwift = "iosApp\iosApp\IosPip.swift"
if (Test-Path $pipSwift) {
    $content = Get-Content $pipSwift -Raw
    $content = $content -replace ',\s*\n\s*\)', "`n    )"
    Set-Content $pipSwift -Value $content -NoNewline
    Write-Host "[OK] $pipSwift を更新しました" -ForegroundColor Green
}

# 5. iosApp/gen_xcodeproj.rb の修正 (Assets.xcassets無効化)
$genProj = "iosApp\gen_xcodeproj.rb"
if (Test-Path $genProj) {
    $content = Get-Content $genProj -Raw
    $content = $content -replace "app_target\.resources_build_phase\.add_file_reference\(assets_ref\)", "# app_target.resources_build_phase.add_file_reference(assets_ref)"
    $content = $content -replace "config\.build_settings\['ASSETCATALOG_COMPILER_APPICON_NAME'\]", "# config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME']"
    Set-Content $genProj -Value $content -NoNewline
    Write-Host "[OK] $genProj を更新しました" -ForegroundColor Green
}

# 6. iosApp/iosApp/Info.plist の修正 (アプリアイコン設定追加)
$infoPlist = "iosApp\iosApp\Info.plist"
if (Test-Path $infoPlist) {
    $content = Get-Content $infoPlist -Raw
    if ($content -notmatch 'CFBundleIcons') {
        $iconXml = @"
	<key>CFBundleIcons</key>
	<dict>
		<key>CFBundlePrimaryIcon</key>
		<dict>
			<key>CFBundleIconFiles</key>
			<array>
				<string>AppIcon60x60</string>
			</array>
		</dict>
	</dict>
	<key>CFBundleIcons~ipad</key>
	<dict>
		<key>CFBundlePrimaryIcon</key>
		<dict>
			<key>CFBundleIconFiles</key>
			<array>
				<string>AppIcon60x60</string>
				<string>AppIcon76x76</string>
			</array>
		</dict>
	</dict>
</dict>
"@
        $content = $content -replace '</dict>\s*$', $iconXml
        Set-Content $infoPlist -Value $content -NoNewline
        Write-Host "[OK] $infoPlist を更新しました" -ForegroundColor Green
    }
}

