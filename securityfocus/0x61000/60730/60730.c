char vuln_func(int a1, int a2)
{
int v6;
v3 = (a2 + 12);
v9 = -119;
v10 = 74;
v11 = -4;
// Declaration of few more local variables. Ommited
v2 = (v3 + 6);
if ( v2 >= 2 )
{
v6 = ((a2 + 24) + 40 * v2 - 20); // <<---
v5 = before_crash1(a2, v2 - 1, 0);
if ((v5 + v6) <= (a2 + 4) )
{
before_crash2(&v9, 25);
result = crash_function((int)&v8, v6 + a2, v5, (int)&v7); //Vulnerable function calling the crash_function. Inside this peid prog. will crash
}
else
{
result = 0;
}
}
else
{
result = 0;
}
return result;
}
