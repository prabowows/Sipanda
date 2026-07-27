$ErrorActionPreference = 'Stop'
$districts = @('Semarang Utara', 'Semarang Tengah', 'Semarang Selatan')

$dartCode = "import 'package:latlong2/latlong.dart';`n"
$dartCode += "class DistrictPolygons {`n"

foreach ($d in $districts) {
    Write-Host "Fetching $d ..."
    $url = "https://nominatim.openstreetmap.org/search.php?q=$($d.Replace(' ', '+'))+Kota+Semarang&polygon_geojson=1&format=jsonv2"
    
    # Needs a delay to respect Nominatim limits
    Start-Sleep -Seconds 2
    $response = Invoke-RestMethod -Uri $url -Headers @{"User-Agent" = "SiPanda/1.0 (contact@example.com)"}
    
    if ($response.Count -gt 0) {
        $feature = $response[0]
        $geojson = $feature.geojson
        $coordsStr = ""
        
        if ($geojson.type -eq "Polygon") {
            $coords = $geojson.coordinates[0]
            foreach ($c in $coords) {
                $coordsStr += "    const LatLng($($c[1]), $($c[0])),`n"
            }
        } elseif ($geojson.type -eq "MultiPolygon") {
            $coords = $geojson.coordinates[0][0]
            foreach ($c in $coords) {
                $coordsStr += "    const LatLng($($c[1]), $($c[0])),`n"
            }
        }
        
        $varName = $d.Replace(' ', '').ToLower()
        $dartCode += "`n  static const List<LatLng> $varName = [`n$coordsStr  ];`n"
    } else {
        Write-Host "No data for $d"
    }
}
$dartCode += "}`n"

$dartCode = $dartCode -replace ",", "," # Ensure encoding safety if needed
Out-File -FilePath "d:\AntiGravity\AntiGravity-Project\SiPanda\sipanda_app\lib\features\citizen\widgets\district_polygons.dart" -InputObject $dartCode -Encoding utf8
Write-Host "Done!"
