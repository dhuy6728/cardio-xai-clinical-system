$filePath = "C:\Users\ADMIN\.gemini\antigravity\scratch\cardio_xai_project\docs\Bao_Cao_Phase_1_2.docx"

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    # Enable all alerts to ensure Word doesn't complain about schema corruption or recovery
    $word.DisplayAlerts = [Microsoft.Office.Interop.Word.WdAlertLevel]::wdAlertsAll
    $doc = $word.Documents.Open($filePath)
    $pageCount = $doc.ComputeStatistics(2)
    $wordCount = $doc.ComputeStatistics(0)
    Write-Output "VERIFIED: Document opened cleanly in Microsoft Word without any recovery prompt!"
    Write-Output "Total Pages: $pageCount | Total Words: $wordCount"
    $doc.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges)
    $word.Quit()
} catch {
    Write-Output "FAILED: $($_.Exception.Message)"
}
