                #define _XOPEN_SOURCE 600
                #include <stdlib.h> /* posix_memalign() should be defined here */
                /* some systems break if #include <malloc.h> used */
		static void test_memalign (size_t boundary, size_t size) {
		    void *mem = 0;
		    if (posix_memalign (&mem, boundary, size) != 0 || !mem)
			exit (1);
                    else
                      free (mem);
		}
		int main() {
		    test_memalign (  128,   128 - 2 * sizeof (void*));
		    test_memalign (  256,   256 - 2 * sizeof (void*));
		    test_memalign (  512,   512 - 2 * sizeof (void*));
		    test_memalign ( 1024,  1024 - 2 * sizeof (void*));
		    test_memalign ( 2048,  2048 - 2 * sizeof (void*));
		    test_memalign ( 4096,  4096 - 2 * sizeof (void*));
		    test_memalign ( 8192,  8192 - 2 * sizeof (void*));
		    test_memalign (16384, 16384 - 2 * sizeof (void*));
		    test_memalign (32768, 32768 - 2 * sizeof (void*));
		    exit (0); /* success */
		}
