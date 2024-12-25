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
    $retentionPolicy = $job.BackupStorageOptions.RetainCycles
    
    # VM'leri al
    $vms = $job.GetObjectsInJob() | ForEach-Object {
        try {
            $vmInfo = $_
            [PSCustomObject]@{
                'VM_Adı' = $vmInfo.Name
                'Boyut_GB' = [math]::Round(($vmInfo.Info.UsedSpaceGB), 2)
                'Durum' = $vmInfo.Type
            }
        } catch {
            Write-Warning "VM bilgisi alınamadı: $_"
        }
    }
    
    [PSCustomObject]@{
        'Görev Adı' = $job.Name
        'Açıklama' = $job.Description
        'Tür' = $job.JobType
        'Zamanlama' = if ($schedule.Periodic) {"Her $($schedule.FullPeriod) dakikada bir"} else {"Özel zamanlama"}
        'Çalışma Günleri' = ($schedule.DailyOptions.Days -join ', ')
        'Son Çalışma' = $job.LatestRunLocal
        'Son Durum' = $job.GetLastResult()
        'Retention (gün)' = $retentionPolicy
        'Simple Retention' = $options.SimpleRetentionRestorePoints.Count
        'GFS Policy' = if ($options.GfsPolicy.IsEnabled) {
            "Yıllık: $($options.GfsPolicy.KeepYearly), Aylık: $($options.GfsPolicy.KeepMonthly), Haftalık: $($options.GfsPolicy.KeepWeekly)"
        } else { "Pasif" }
        'Depolama' = $storage.Name
        'Sıkıştırma' = $options.BackupStorageOptions.CompressionLevel
        'Şifreleme' = if ($options.BackupStorageOptions.EncryptionEnabled) {"Aktif"} else {"Pasif"}
        'VM_Listesi' = ($vms | ConvertTo-Json)
        'VM_Sayısı' = $vms.Count
        'Toplam_VM_Boyutu_GB' = [math]::Round(($vms | Measure-Object -Property Boyut_GB -Sum).Sum, 2)
    }
}

# Export
$date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$exportPath = "C:\VeeamReports\job_details_$date.csv"
$jobDetails | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

# VM detayları için ayrı export
$vmDetailsPath = "C:\VeeamReports\vm_details_$date.csv"
$jobDetails | ForEach-Object {
    $jobName = $_.('Görev Adı')
    $vms = $_.VM_Listesi | ConvertFrom-Json
    $vms | ForEach-Object {
        [PSCustomObject]@{
            'Görev_Adı' = $jobName
            'VM_Adı' = $_.VM_Adı
            'Boyut_GB' = $_.Boyut_GB
            'Durum' = $_.Durum
        }
    }
} | Export-Csv -Path $vmDetailsPath -NoTypeInformation -Encoding UTF8

Disconnect-VBRServer

Write-Host "Raporlar oluşturuldu: 
Görev detayları: $exportPath
VM detayları: $vmDetailsPath"
