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

#include <multiboot.h>

#define GREEN_TEXT	0x02
#define RED_TEXT	0x04
#define PLAIN_TEXT	0x07
#define YELLOW_TEXT 0x0E

void puts_fail(const char *restrict message, unsigned long value);
void puts_ok(const char *restrict message);
void puts(const char* restrict str, unsigned char attr);
void putc(const char c, unsigned char attr);

#define assert(_cond, _message) do { \
	if ((_cond)) \
		puts_ok((_message));\
	else \
		puts_fail((_message), 0);\
} while(0);

int strcmp(const char *restrict s0, const char *restrict s1);

////////////////////////////////////////////////////////////////////////////////

__attribute__((noreturn)) void kmain(
	struct multiboot_info *mb, multiboot_uint32_t boot_magic
) {
	/* setup the VGA Text Mode display, that will be used for showing the
	   report */
	for (register int i = 0; i < 2000; ++i)
		((unsigned short *)0xB8000)[i] = ' ' | (PLAIN_TEXT << 8);

	/* perform the required checks to ensure that multiboot compliance is
	   ok */
	puts_ok("stub kernel launched");

	assert(
		boot_magic == MULTIBOOT_BOOTLOADER_MAGIC, 
		"parameter 'boot_magic' contains value '0x2BADB002'."
	);

	assert(
		mb != 0,
		"multiboot_info reference must not be NULL."
	);

	assert(
		strcmp(mb->boot_loader_name, "vboot bootloader v0.1") == 0,
		"mb->boot_loader_name is set and provided."
	);
	puts("boot_loader_name: ", PLAIN_TEXT);
	puts((void *)mb->boot_loader_name, YELLOW_TEXT);
	puts("\n", PLAIN_TEXT);
	/* make sure we don't fall out of the end of the kernel. */
	for (;;)
		__asm__ __volatile__("hlt");
}

////////////////////////////////////////////////////////////////////////////////

static unsigned short crsx = 0;
static unsigned short crsy = 0;

void scroll(void)
{
	register unsigned short *ptr = (void *)0xB8000;
	register unsigned int size = (80 * (25 - 1));
	for (register unsigned int offset = 0; offset < size; ++offset) {
		ptr[offset] = ptr[offset + 80];
	}
	for (register unsigned int offset = 0; offset < 80; ++offset) {
		ptr[offset + size] = ' ' | (PLAIN_TEXT << 8);
	}
}

void puts(const char* restrict str, unsigned char attr)
{
	while (*str)
		putc(*str++, attr);
}

void puts_fail(const char *restrict message, unsigned long value)
{
	putc('[', PLAIN_TEXT);
	puts("FAIL", RED_TEXT);
	puts("] ", PLAIN_TEXT);
	puts(message, PLAIN_TEXT);
	putc('\n', PLAIN_TEXT);
}

void puts_ok(const char *restrict message)
{
	putc('[', PLAIN_TEXT);
	puts(" OK ", GREEN_TEXT);
	puts("] ", PLAIN_TEXT);
	puts(message, PLAIN_TEXT);
	putc('\n', PLAIN_TEXT);
}

void putc(const char c, unsigned char attr)
{
	if (c < ' ') {
		/* The character isn't directly printable and is technically a
		   "control" character. */
		switch (c) {
			case '\0': /* NUL */
				break;
			case '\n': /* Line feed */
				++crsy;
				crsx = 0;
				break;
			default:
				break;
		}
	}
	else if (c >= ' ') {
		/* The character is a printable one. Just print it to screen. */
		((unsigned short *)0xB8000)[(crsy * 80) + crsx++] = c | (attr << 8);
	}

	if (crsx >= 80) {
		crsx =0;
		++crsy;
	}
	if (crsy >= 25) {
		scroll();
		--crsy;
	}
}

////////////////////////////////////////////////////////////////////////////////

int strcmp(const char *restrict s0, const char *restrict s1)
{
	while (*s0 == *s1++) {
		if (*s0++ == '\0')
			return 0;
	}
	return (*(const char *)s0 - *(const char *)(s1 - 1));
}