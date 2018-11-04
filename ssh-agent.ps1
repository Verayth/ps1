$env:SSH_AUTH_SOCK="c:\temp\.ssh-pageant-${env:USERNAME}"
ssh-pageant -cr -a $env:SSH_AUTH_SOCK
