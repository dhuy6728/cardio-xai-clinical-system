import zipfile
import lxml.etree

z = zipfile.ZipFile("docs/Bao_Cao_Phase_1_2.docx")
doc_xml = z.read("word/document.xml")
tree = lxml.etree.fromstring(doc_xml)
ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}

# Correct ECMA-376 schema sequence for tcPr:
# cnfStyle, tcW, gridSpan, hMerge, vMerge, tcBorders, shd, noWrap, tcMar, textDirection, tcFitText, vAlign, hideMark, headers, cellIns, cellDel, cellMerge, tcPrChange
tcPr_order = [
    "cnfStyle", "tcW", "gridSpan", "hMerge", "vMerge", "tcBorders",
    "shd", "noWrap", "tcMar", "textDirection", "tcFitText", "vAlign",
    "hideMark", "headers", "cellIns", "cellDel", "cellMerge", "tcPrChange"
]
order_map = {name: i for i, name in enumerate(tcPr_order)}

errors = []
for i, tcPr in enumerate(tree.xpath("//w:tcPr", namespaces=ns)):
    tags = [lxml.etree.QName(child).localname for child in tcPr]
    indices = [order_map.get(t, 999) for t in tags]
    if indices != sorted(indices):
        errors.append((i, tags))

print(f"Total tcPr with sequence violations: {len(errors)} / {len(tree.xpath('//w:tcPr', namespaces=ns))}")
for i, tags in errors[:5]:
    print(f"Cell {i} tags: {tags}")
