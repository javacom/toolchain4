#include <sys/types.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    setuid(0);
    setgid(0);
    execvp(argv[1], argv + 1);
}
