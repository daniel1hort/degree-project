#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "core.h"

char filename1[SMALL_SIZE + 1];
char filename2[SMALL_SIZE + 1];
char filename3[SMALL_SIZE + 1];
int size = 0;

void parse_options(int argc, char** argv) {
	if (argc < 2) {
		fprintf_s(stderr, "first argument must be a file\n");
		exit(EXIT_FAILURE);
	}

	strcpy_s(filename1, SMALL_SIZE + 1, argv[1]);
	strcpy_s(filename2, SMALL_SIZE + 1, filename1);
	strcat_s(filename2, SMALL_SIZE + 1, ".out");
	strcpy_s(filename3, SMALL_SIZE + 1, "a.bin");
	if (argc >= 3) {
		strcpy_s(filename3, SMALL_SIZE + 1, argv[2]);
	}
	if (argc >= 4) {
		int value;
		int result = sscanf_s(argv[3], "%d", &value);
		if (result == 0) {
			fprintf_s(stderr, "third argument must be a number, default value 0\n");
		}
		else {
			size = value;
		}
	}
}

int main(int argc, char** argv) {
	parse_options(argc, argv);
	FILE* file1, * file2, * file3;
	fopen_s(&file1, filename1, "r");
	if (file1 == NULL) {
		fprintf_s(stderr, "no such file \"%s\"\n", filename1);
		exit(EXIT_FAILURE);
	}
	
	fopen_s(&file2, filename2, "w");
	step1(file1, file2);

	fopen_s(&file3, filename3, "wb");
	fclose(file2);
	freopen_s(&file2, filename2, "r", file2);
	step2(file2, file3, size);

	_fcloseall();
	return 0;
}