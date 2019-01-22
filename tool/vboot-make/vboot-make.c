/*
 Copyright (c) 2019 Tom Hancocks
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <unistd.h>
#include <wordexp.h>

////////////////////////////////////////////////////////////////////////////////

static const char *version_string = 
"vboot-make v0.1 -- vboot disk image make tool\n"
"Copyright (c) 2019 Tom Hancocks\n";

static const char *help_string = 
"vboot-make v0.1\n"
"\tA tool to create disk images with vboot install upon them.\n\n"
"\033[1mUsage\033[0m\n"
"\tvboot-make [Options] file\n\n"
"\033[1mOptions\033[0m\n"
"\t-T  The type of disk media to produce.\n"
"\t\tfd : 1_44MiB Floppy Disk Image (default)\n"
"\t\thd : Hard Disk Image (80MiB Default)\n"
"\t-S  The size of the disk image in sectors.\n"
"\t-s  The size of a sector in bytes.\n"
"\t-f  The file system format of the disk image produced.\n"
"\t\trfs : RawFS disk image (default)\n"
"\t-k  Kernel binary to be pre-installed in the disk image.\n"
"\t-r  Ramdisk to be pre-installed in the disk image.\n"
"\t-b  Boot message to be displayed at boot time. Maximum 32 bytes.\n"
"\t    This may not be used depending on the file system format selected.\n"

"";


////////////////////////////////////////////////////////////////////////////////

const char *resolve_path(char *path)
{
	// Perform expansion on the the path.
    wordexp_t exp_result;
    wordexp(path, &exp_result, 0);

    unsigned long len = strlen(exp_result.we_wordv[0]);
    char *result = calloc(len + 1, sizeof(*result));
    memcpy(result, exp_result.we_wordv[0], len);

    wordfree(&exp_result);

    return result;
}

const char *copystr(char *str)
{
    unsigned long len = strlen(str);
    char *result = calloc(len + 1, sizeof(*result));
    char *r = result;

    while (*str) {
    	if (*str == '\\' && *(str + 1) == 'r') {
    		*r++ = '\r';
    		str++;
    	}
    	else if (*str == '\\' && *(str + 1) == 'n') {
    		*r++ = '\n';
    		str++;
    	}
    	else {
    		*r++ = *str;
    	}
    	str++;
    }

    return result;
}

////////////////////////////////////////////////////////////////////////////////



int main(int argc, char const *argv[])
{
	/* If there are no arguments then just dump out a version string */
	if (argc <= 1) {
		printf("%s", version_string);
		return 0;
	}

	/* There are arguments. Parse them and determine what to do accordingly. */
	int c = 0;
	while ((c = getopt(argc, (char **)argv, "h")) != -1) {
		switch (c) {
			case 'h':
				printf("%s", help_string);
				return 0;
			default:
				break;
		}
	}

	return 0;
}