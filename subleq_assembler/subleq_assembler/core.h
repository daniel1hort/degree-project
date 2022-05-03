#pragma once

#ifndef __CORE_H__
#define __CORE_H__

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LABEL_LENGTH 16
#define SMALL_SIZE 256

typedef int16_t static_ptr;
typedef enum {FALSE, TRUE} BOOL;

typedef enum error_type {
	ERROR_INVALID_DATA_PARAM,
	ERROR_INVALID_LABEL_NAME,
	ERROR_UNKNOWN_DIRECTIVE,
	ERROR_MULTIPLY_DEFINED_LABEL,
	ERROR_LABEL_NOT_DEFINED,
	ERROR_UNDEFINED_SYMBOL,
	ERROR_INTERNAL_SYMBOL_REDEFINED,
	ERROR_SYMBOL_ZERO_READONLY,
	ERROR_SYMBOL_END_READONLY
} ERROR_TYPE;

typedef enum directive_type {
	DIRECTIVE_NONE,
	DIRECTIVE_ORG,
	DIRECTIVE_DATA,
	DIRECTIVE_END,
	//DIRECTIVE_MACRO,
	//DIRECTIVE_ENDM
} DIRECTIVE_TYPE;

typedef enum label_status {
	LABEL_STATUS_VALID,
	LABEL_STATUS_MULTIPLY_DEFINED,
	LABEL_STATUS_INVALID,
	LABEL_STATUS_UNDEFINED
} LABEL_STATUS;

typedef enum param_status{
	PARAM_STATUS_EMPTY = 0,
	PARAM_STATUS_VALUE = 1,
	PARAM_STATUS_NAME  = 2
} PARAM_STATUS;

typedef struct label_def {
	char name[MAX_LABEL_LENGTH + 1];
	uint64_t value;
	LABEL_STATUS status;
	int32_t line;
	int32_t column;
}LABEL_DEF;

typedef struct param_def {
	char name[MAX_LABEL_LENGTH + 1];
	uint64_t value;
	PARAM_STATUS status;
} PARAM_DEF;

typedef struct line_def {
	static_ptr label;
	DIRECTIVE_TYPE directive;
	PARAM_DEF params[3];
} LINE_DEF;

extern LABEL_DEF labels[INT16_MAX];
extern int labels_count;

void step1(FILE* stream1, FILE* stream2);
void step2(FILE* stream1, FILE* stream2);

#endif
