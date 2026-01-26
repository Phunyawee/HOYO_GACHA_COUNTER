# FILE: SettingChild\TabEmailChild\02_Styles.ps1
# DESCRIPTION: HTML Generation Logic (The 10 Styles)

function Get-EmailHtmlBody {
    param(
        [string]$StyleName,
        [string]$RowsHTML
    )

    $Meta = "<meta charset='utf-8'>"
    
    switch ($StyleName) {
        "Universal Card" {
            return "<html><head>$Meta<style>
                body{background:#121212;color:#eee;font-family:'Segoe UI',sans-serif;margin:0;padding:10px;}
                .card{background:#1e1e1e;border-radius:12px;overflow:hidden;box-shadow:0 4px 15px rgba(0,0,0,0.5);border:1px solid #333;}
                .head{background:linear-gradient(180deg, #2a2a2a 0%, #1e1e1e 100%);padding:15px;border-bottom:1px solid #333;text-align:center;}
                .head h2{margin:0;font-size:18px;color:#fff;text-transform:uppercase;letter-spacing:1px;}
                .head p{margin:2px 0 0;font-size:11px;color:#888;}
                table{width:100%;border-collapse:collapse;margin-top:10px;}
                td{padding:10px;border-bottom:1px solid #2a2a2a;}
                .c2{color:#FFD700;font-weight:bold;} .c3{color:#0f0;}
            </style></head><body>
            <div class='card'><div class='head'><h2>GACHA REPORT</h2><p>Universal Log System</p></div>
            <div style='padding:10px;'><table>$RowsHTML</table></div></div></body></html>"
        }
        "Classic Table" {
            return "<html><head>$Meta<style>body{font-family:Tahoma;background:#fff;padding:10px;} table{width:100%;border-collapse:collapse;} td,th{border:1px solid #999;padding:5px;color:#000;}</style></head><body><h3>Classic Report</h3><table>$RowsHTML</table></body></html>"
        }
        "Terminal Mode" {
            return "<html><head>$Meta<style>body{background:#000;color:#0f0;font-family:Consolas,monospace;padding:10px;} .box{border:1px dashed #0f0;padding:5px;} td{padding:2px;}</style></head><body><div>> SYSTEM_READY</div><br><div class='box'><table>$RowsHTML</table></div></body></html>"
        }
        "Modern Dark" {
            return "<html><head>$Meta<style>body{background:#222;color:#ddd;font-family:sans-serif;padding:10px;} table{width:100%;} td{padding:12px;border-bottom:1px solid #444;} .c2{color:#4db8ff;}</style></head><body><h3 style='border-left:4px solid #4db8ff;padding-left:10px;'>Modern Log</h3><table>$RowsHTML</table></body></html>"
        }
        "Minimalist White" {
            return "<html><head>$Meta<style>body{background:#f9f9f9;color:#333;font-family:'Helvetica Neue',sans-serif;padding:15px;} table{width:100%;} td{padding:15px 5px;border-bottom:1px solid #eee;} .c2{font-weight:600;}</style></head><body><div style='text-align:center;margin-bottom:20px;color:#aaa;'>SIMPLE REPORT</div><table>$RowsHTML</table></body></html>"
        }
        "Cyber Neon" {
            return "<html><head>$Meta<style>body{background:#050505;color:#fff;font-family:Verdana;padding:10px;} .wrap{border:2px solid #ff00de;box-shadow:0 0 10px #ff00de;padding:10px;} td{padding:8px;border-bottom:1px solid #00eaff;} .c2{color:#ff00de;text-shadow:0 0 5px #ff00de;} .c3{color:#00eaff;}</style></head><body><div class='wrap'><h3 style='color:#00eaff;text-align:center;'>CYBER_LOG</h3><table>$RowsHTML</table></div></body></html>"
        }
        "Blueprint" {
            return "<html><head>$Meta<style>body{background:#003366;color:#fff;font-family:Courier New;padding:10px;} table{width:100%;border:2px solid #fff;} td{border:1px solid #88aadd;padding:5px;} .c2{color:#fff;text-decoration:underline;}</style></head><body><h4 style='border:1px solid #fff;display:inline-block;padding:5px;'>BLUEPRINT V.1</h4><br><br><table>$RowsHTML</table></body></html>"
        }
        "Vintage Log" {
            return "<html><head>$Meta<style>body{background:#FDF5E6;color:#5c4033;font-family:'Georgia',serif;padding:15px;} table{width:100%;border-top:2px double #8B4513;border-bottom:2px double #8B4513;} td{padding:10px;font-style:italic;}</style></head><body><h2 style='text-align:center;border-bottom:1px solid #5c4033;'>Adventurer Log</h2><table>$RowsHTML</table></body></html>"
        }
        "Excel Sheet" {
            return "<html><head>$Meta<style>body{background:#fff;font-family:Arial;padding:10px;} table{border-collapse:collapse;width:100%;} td{border:1px solid #ccc;padding:4px;} tr:first-child{background:#f0f0f0;}</style></head><body><div style='background:#217346;color:white;padding:5px;font-weight:bold;'>Sheet1</div><br><table>$RowsHTML</table></body></html>"
        }
        "Gacha Pop" {
            return "<html><head>$Meta<style>body{background:#ffe6f2;color:#555;font-family:'Comic Sans MS',sans-serif;padding:10px;} .pop{background:white;border-radius:15px;padding:10px;border:3px dashed #ff66b2;} td{padding:8px;border-bottom:1px dotted #ff99cc;} .c2{color:#ff66b2;font-weight:bold;}</style></head><body><div class='pop'><h3 style='text-align:center;color:#ff66b2;'>★ Gacha Time ★</h3><table>$RowsHTML</table></div></body></html>"
        }
        Default { return "<html><body>Style Not Found</body></html>" }
    }
}