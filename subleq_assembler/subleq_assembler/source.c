#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "core.h"

char filename2[SMALL_SIZE + 1];

int main(int argc, char** argv) {
	if (argc < 2) {
		fprintf_s(stderr, "first argument must be a file\n");
		exit(EXIT_FAILURE);
	}

	char* filename1 = argv[1];
	FILE* file1, *file2;
	fopen_s(&file1, filename1, "r");
	if (file1 == NULL) {
		fprintf_s(stderr, "no such file \"%s\"\n", filename1);
		exit(EXIT_FAILURE);
	}
	
	strcpy_s(filename2, SMALL_SIZE + 1, filename1);
	strcat_s(filename2, SMALL_SIZE + 1, ".v2");
	fopen_s(&file2, filename2, "w");

	step1(file1, file2);
	//step2();

	_fcloseall();
	return 0;
}