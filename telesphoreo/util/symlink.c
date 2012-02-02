#include <unistd.h>

int main(int argc, const char *argv[]) {
    setuid(0);
    setgid(0);
    unlink(argv[2]);
    symlink(argv[1], argv[2]);
    return 0;
}
