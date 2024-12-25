# Veeam PowerShell modülünü yükle
Import-Module Veeam.Backup.PowerShell

# Veeam sunucusuna bağlan
Connect-VBRServer -Server "localhost"

# Tüm görevleri al
$jobs = Get-VBRJob

# Detaylı görev bilgilerini topla
$jobDetails = foreach ($job in $jobs) {
    $schedule = $job.ScheduleOptions
    $options = $job.Options
    $storage = $job.GetTargetRepository()
    
    [PSCustomObject]@{
        'Görev Adı' = $job.Name
        'Açıklama' = $job.Description
        'Tür' = $job.JobType
        'Zamanlama' = if ($schedule.Periodic) {"Her $($schedule.FullPeriod) dakikada bir"} else {"Özel zamanlama"}
        'Son Çalışma' = $job.LatestRunLocal
        'Son Durum' = $job.GetLastResult()
        'Aktif' = $job.IsScheduleEnabled
        'Depolama' = $storage.Name
        'Sıkıştırma' = $options.BackupStorageOptions.CompressionLevel
        'Şifreleme' = if ($options.BackupStorageOptions.EncryptionEnabled) {"Aktif"} else {"Pasif"}
        'GFS Aktif' = $options.GfsPolicy.IsEnabled
        'Kaynak Sayısı' = ($job.GetObjectsInJob()).Count
    }
}

# Tarihi al ve dosya adı oluştur
$date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$exportPath = "C:\VeeamReports\job_details_$date.csv"

# CSV olarak export et
$jobDetails | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

# Bağlantıyı kapat
Disconnect-VBRServer

Write-Host "Görev detayları export edildi: $exportPath"
