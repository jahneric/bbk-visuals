# Mini-Webserver für die bbk-Visuals: liefert diesen Ordner offline unter http://localhost:8080 aus.
param([switch]$NoBrowser)
$root = $PSScriptRoot
$types = @{
  ".html" = "text/html; charset=utf-8"; ".js" = "text/javascript"; ".mjs" = "text/javascript"
  ".css" = "text/css"; ".wasm" = "application/wasm"; ".woff2" = "font/woff2"; ".png" = "image/png"
  ".jpg" = "image/jpeg"; ".svg" = "image/svg+xml"; ".tflite" = "application/octet-stream"
}
$listener = New-Object System.Net.HttpListener
foreach ($port in 8080..8090) {
  try { $listener.Prefixes.Clear(); $listener.Prefixes.Add("http://localhost:$port/"); $listener.Start(); break }
  catch { $listener = New-Object System.Net.HttpListener }
}
$url = $listener.Prefixes | Select-Object -First 1
Write-Host "bbk visuals laeuft auf $url  (Fenster offen lassen, schliessen = beenden)"

$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LocalAppData\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($NoBrowser) {} elseif ($chrome) { Start-Process $chrome "--new-window $url" } else { Start-Process $url }

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart("/"))
  if ($path -eq "") { $path = "index.html" }
  $file = [IO.Path]::GetFullPath((Join-Path $root $path))
  $res = $ctx.Response
  if ($file.StartsWith($root) -and (Test-Path $file -PathType Leaf)) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $res.ContentType = if ($types[$ext]) { $types[$ext] } else { "application/octet-stream" }
    $res.ContentLength64 = $bytes.Length
    try { $res.OutputStream.Write($bytes, 0, $bytes.Length) } catch {}
  } else { $res.StatusCode = 404 }
  $res.Close()
}
