/*Create rainbow table for guessing wp-backup-db v2.2.4 backup path 
Larry W. Cashdollar*/

#include 
#include 

int
main (void)
{
 char string[16] = "0123456789abcdef";
 int x, y, z, a, b;

 for (x = 0; x < 16; x++)
   {
     for (y = 0; y < 16; y++)
        {
          for (z = 0; z < 16; z++)
            {
              for (a = 0; a < 16; a++)
                {
                  for (b = 0; b < 16; b++)
                    {
                      printf ("%c%c%c%c%c\n", string[x], string[y], string[z],
                              string[a], string[b]);
                    }
                }
            }
        }
   }
return(0);
}
