$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root "default.project.json"
$output = Join-Path $root "sourcemap.json"

Push-Location $root
try {
	$previousErrorActionPreference = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	$rojoOutput = $null
	$rojoStatus = 1

	try {
		$rojoOutput = & rojo sourcemap $project -o $output 2>&1
		$rojoStatus = $LASTEXITCODE
	} catch {
		$rojoOutput = $_
		$rojoStatus = 1
	} finally {
		$ErrorActionPreference = $previousErrorActionPreference
	}

	if ($rojoStatus -eq 0) {
		if ($rojoOutput) {
			$rojoOutput
		}
		return
	}

	$toolRoot = Join-Path $env:USERPROFILE ".aftman\tool-storage\rojo-rbx\rojo"
	$rojo = Get-ChildItem -LiteralPath $toolRoot -Filter "rojo.exe" -Recurse -ErrorAction SilentlyContinue |
		Sort-Object FullName -Descending |
		Select-Object -First 1

	if (-not $rojo) {
		$rojoOutput
		throw "Could not find Rojo. Run aftman install, then try again."
	}

	& $rojo.FullName sourcemap $project -o $output
} finally {
	Pop-Location
}
