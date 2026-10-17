$filePath = "C:\Users\ADMIN\.gemini\antigravity\scratch\cardio_xai_project\docs\Bao_Cao_Phase_1_2.docx"

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = [Microsoft.Office.Interop.Word.WdAlertLevel]::wdAlertsNone
    $doc = $word.Documents.Open($filePath)
    Write-Output "SUCCESS: Opened document in Microsoft Word!"
    $doc.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges)
    $word.Quit()
} catch {
    Write-Output "FAILED: $($_.Exception.Message)"
}
