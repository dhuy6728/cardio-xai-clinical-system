import win32com.client
import sys
from pathlib import Path

docx_path = Path("docs/Bao_Cao_Phase_1_2.docx").resolve()

try:
    word = win32com.client.Dispatch("Word.Application")
    word.Visible = False
    doc = word.Documents.Open(str(docx_path))
    print(f"SUCCESS: Opened document '{doc.Name}' in MS Word! Page count: {doc.ComputeStatistics(2)}")
    doc.Close(False)
    word.Quit()
except Exception as e:
    print(f"FAILED to open in MS Word: {e}")
    sys.exit(1)
