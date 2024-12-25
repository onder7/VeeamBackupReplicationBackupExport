# Veeam PowerShell modülünü yükle
Import-Module Veeam.Backup.PowerShell

# Bağlantı parametreleri
$VBRServer = "localhost"
$BackupServer = Connect-VBRServer -Server $VBRServer

# Tüm yedekleme işlerini al
$backupJobs = Get-VBRJob

# Rapor için tarih
$date = Get-Date -Format "yyyy-MM-dd"
$exportPath = "C:\VeeamReports\backup_report_$date.csv"

# Yedekleme detaylarını topla
$backupDetails = foreach ($job in $backupJobs) {
    $lastSession = $job.FindLastSession()
    $lastRun = $job.LatestRunLocal
    
    [PSCustomObject]@{
        'İş Adı' = $job.Name
        'Durum' = $job.GetLastResult()
        'Son Çalışma' = $lastRun
        'Başarı Durumu' = $lastSession.Result
        'Başlangıç Zamanı' = $lastSession.CreationTime
        'Bitiş Zamanı' = $lastSession.EndTime
        'İşlem Süresi (Dakika)' = [math]::Round(($lastSession.EndTime - $lastSession.CreationTime).TotalMinutes, 2)
        'Veri Boyutu (GB)' = [math]::Round($lastSession.BackupStats.DataSize / 1GB, 2)
        'Sıkıştırılmış Boyut (GB)' = [math]::Round($lastSession.BackupStats.BackupSize / 1GB, 2)
        'Değişen Veri (GB)' = [math]::Round($lastSession.BackupStats.DataRead / 1GB, 2)
    }
}

# CSV olarak dışa aktar
$backupDetails | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

# Bağlantıyı kapat
Disconnect-VBRServer

Write-Host "Yedekleme raporu başarıyla oluşturuldu: $exportPath"
