---
type: condition
name: <string>
subtype: <string|null>
icd10: <string|null>          # optional ICD-10 code
diag_date: <YYYY-MM-DD|null>  # null if self-reported
diagnosed_by: <string|null>
status: <active|remission|resolved>
severity: <mild|moderate|severe|null>
treatment: <string|null>
source: <string>               # medical-record | self-report | genetic-test
version: <int>
tags: [<list>]
---