#pragma once

#ifndef __CORE_H__
#define __CORE_H__

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>

#define MAX_LABEL_LENGTH 16
#define SMALL_SIZE 256
#define NOT_IMPLEMENTED assert(0 && "NOT IMPLEMENTED");

typedef int16_t static_ptr;
typedef enum {FALSE, TRUE} BOOL;

typedef enum error_type {
	ERROR_INVALID_DATA_PARAM,
	ERROR_INVALID_SYMBOL_NAME,
	ERROR_UNKNOWN_DIRECTIVE,
	ERROR_MULTIPLY_DEFINED_LABEL,
	ERROR_UNDEFINED_SYMBOL,
	ERROR_INTERNAL_SYMBOL_REDEFINED,
	ERROR_SYMBOL_ZERO_READONLY,
	ERROR_MACRO_INSIDE_MACRO,
	ERROR_ENDM_OUTSIDE_MACRO,
	ERROR_MACRO_NAME_MISSING,
	//ERROR_MAX_ARGUMENTS_COUNT_EXEEDED,
	//ERROR_TOO_MANY_ARGUMENTS,
	//ERROR_TOO_FEW_ARGUMENTS,
} ERROR_TYPE;

typedef enum directive_type {
	DIRECTIVE_NONE,
	DIRECTIVE_ORG,
	DIRECTIVE_DATA,
	DIRECTIVE_END,
	DIRECTIVE_MACRO,
	DIRECTIVE_ENDM
} DIRECTIVE_TYPE;

typedef enum line_type {
	LINE_INSTRUCTION,
	LINE_DIRECTIVE,
	LINE_MACRO
} LINE_TYPE;

typedef enum label_status {
	LABEL_STATUS_VALID,
	LABEL_STATUS_MULTIPLY_DEFINED,
	LABEL_STATUS_INVALID,
	LABEL_STATUS_UNDEFINED
} LABEL_STATUS;

typedef enum label_scope {
	LABEL_SCOPE_GLOBAL,
	LABEL_SCOPE_MACRO
} LABEL_SCOPE;

typedef enum param_status{
	PARAM_STATUS_EMPTY = 0,
	PARAM_STATUS_VALUE = 1,
	PARAM_STATUS_NAME  = 2
} PARAM_STATUS;

typedef struct location {
	int32_t line;
	int32_t column;
} LOCATION;

typedef struct label_def {
	char name[MAX_LABEL_LENGTH + 1];
	uint64_t value;
	LABEL_STATUS status;
	LOCATION location;
	LABEL_SCOPE scope;
}LABEL_DEF;

typedef struct param_def {
	char name[MAX_LABEL_LENGTH + 1];
	uint64_t value;
	PARAM_STATUS status;
	//LOCATION location;
} PARAM_DEF;

typedef struct macro_def {
	char name[MAX_LABEL_LENGTH + 1];
	PARAM_DEF params[5];
	static_ptr first_line;
	int16_t line_count;
	LOCATION location;
} MACRO_DEF;

typedef struct line_def {
	static_ptr label;
	static_ptr macro;
	LINE_TYPE type;
	DIRECTIVE_TYPE directive;
	PARAM_DEF params[5];
} LINE_DEF;

void step1(FILE* stream1, FILE* stream2);
void step2(FILE* stream1, FILE* stream2, int file_size, int word_size);

#endif
