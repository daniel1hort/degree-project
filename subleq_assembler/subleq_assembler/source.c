#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "core.h"

char filename1[SMALL_SIZE + 1];
char filename2[SMALL_SIZE + 1];
char filename3[SMALL_SIZE + 1];
int file_size_in_words = 0;
int word_size_in_bytes = 8;

void parse_options(int argc, char** argv) {
	if (argc < 2) {
		fprintf_s(stderr, "first argument must be a file\n");
		exit(EXIT_FAILURE);
	}

	strcpy_s(filename1, SMALL_SIZE + 1, argv[1]);
	strcpy_s(filename2, SMALL_SIZE + 1, filename1);
	strcat_s(filename2, SMALL_SIZE + 1, ".out");
	strcpy_s(filename3, SMALL_SIZE + 1, "a.bin");

	for (int i = 0; i < 3; i++) {
		int pos = 2 * i + 3;
		if (argc >= pos && (_stricmp(argv[pos - 1], "-o") == 0 || _stricmp(argv[pos - 1], "--output") == 0))
		{
			if (argc >= pos + 1) {
				strcpy_s(filename3, SMALL_SIZE + 1, argv[pos]);
			}
			else {
				fprintf_s(stderr, "%s must have a value\n", argv[pos - 1]);
				exit(EXIT_FAILURE);
			}
		}
		else if (argc >= pos && (_stricmp(argv[pos - 1], "-s") == 0 || _stricmp(argv[pos - 1], "--size") == 0))
		{
			if (argc >= pos + 1) {
				int value;
				int result = sscanf_s(argv[pos], "%d", &value);
				if (result == 0) {
					fprintf_s(stderr, "%s value must be a number, will assume default value 0\n", argv[pos - 1]);
					exit(EXIT_FAILURE);
				}
				else {
					file_size_in_words = value;
				}
			}
			else {
				fprintf_s(stderr, "%s must have a value\n", argv[pos - 1]);
				exit(EXIT_FAILURE);
			}
		}
		else if (argc >= pos && (_stricmp(argv[pos - 1], "-w") == 0 || _stricmp(argv[pos - 1], "--word") == 0))
		{
			if (argc >= pos + 1) {
				int value;
				int result = sscanf_s(argv[pos], "%d", &value);
				if (result == 0) {
					fprintf_s(stderr, "%s value must be a number, will assume default value 8\n", argv[pos - 1]);
					exit(EXIT_FAILURE);
				}
				else if (value < 1 || value > 8) {
					fprintf_s(stderr, "%s value must be between 1 and 8\n", argv[pos - 1]);
					exit(EXIT_FAILURE);
				}
				else {
					word_size_in_bytes = value;
				}
			}
			else {
				fprintf_s(stderr, "%s must have a value\n", argv[pos - 1]);
				exit(EXIT_FAILURE);
			}
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
	step2(file2, file3, file_size_in_words, word_size_in_bytes);

	_fcloseall();
	return 0;
}