#include "core.h"

LABEL_DEF labels[SMALL_SIZE];
int labels_count;
int failed = FALSE;

#pragma region LINE
inline void line_init(LINE_DEF* line) {
	line->directive = DIRECTIVE_NONE;
	line->label = -1;
	line->params[0].empty = TRUE;
	line->params[1].empty = TRUE;
	line->params[2].empty = TRUE;
}

void line_write(LINE_DEF line, FILE* stream) {
	switch (line.directive)
	{
	case DIRECTIVE_NONE:
		for (int i = 0; i < 3; i++)
			if (line.params[i].empty == FALSE)
				fprintf_s(stream, "%s ", line.params[i].name);
		break;
	case DIRECTIVE_ORG:
		fprintf_s(stream, ".ORG %lld", line.params[0].value);
		break;
	case DIRECTIVE_END:
		fprintf_s(stream, ".END");
		break;
	case DIRECTIVE_DATA:
		fprintf_s(stream, ".DATA %lld", line.params[0].value);
		break;
	}
	fprintf_s(stream, "\n");
}

inline void param_set_value(PARAM_DEF* param, uint64_t value) {
	param->empty = FALSE;
	param->value = value;
}

inline void param_set_name(PARAM_DEF* param, const char* name) {
	param->empty = FALSE;
	strcpy_s(param->name, MAX_LABEL_LENGTH, name);
}
#pragma endregion

#pragma region LABEL
inline void label_set(LABEL_DEF* label, int line, int column, const char * name, LABEL_STATUS status, int64_t value) {
	label->line = line;
	label->column = column;
	strncpy_s(label->name, MAX_LABEL_LENGTH + 1, name, MAX_LABEL_LENGTH);
	label->status = status;
	label->value = value;
}

int label_add(LABEL_DEF label) {
	for (int i = 0; i < labels_count; i++)
		if (_stricmp(label.name, labels[i].name) == 0) {
			labels[i].status = LABEL_STATUS_MULTIPLY_DEFINED;
			return i;
		}
	labels[labels_count++] = label;
	return labels_count - 1;
}

BOOL label_valid_name(const char* name) {
	if (name == NULL)
		return FALSE;

	int length = strlen(name);
	if (length <1 || length > MAX_LABEL_LENGTH)
		return FALSE;

	if (!isalpha(name[0]))
		return FALSE;

	for (int i = 1; i < length; i++)
		if (!isalnum(name[i]))
			return FALSE;

	return TRUE;
}
#pragma endregion

#pragma region UTILS
char* remove_trailing_space(char* name) {
	if (name == NULL)
		return;

	int length = strlen(name);
	for (int i = length - 1; i >= 0 && isspace(name[i]); i--) {
		name[i] = '\0';
		length--;
	}
	
	int i;
	for (i = 0; i < length && isspace(name[i]); i++);
	return name + i;
}

void raise_error(int line, int column, ERROR_TYPE error, const char * info) {
	failed = TRUE;
	switch (error)
	{
	case ERROR_NAN:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: '%s' is not a number.\n", __TIME__, line, column, info);
		break;
	case ERROR_INVALID_LABEL_NAME:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: invalid label name '%s'. A label must start with a letter, may contain digits and must be at most 16 characters long.\n", __TIME__, line, column, info);
		break;
	case ERROR_UNKNOWN_DIRECTIVE:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: unkown directive '%s'.\n", __TIME__, line, column, info);
		break;
	case ERROR_MULTIPLY_DEFINED_LABEL:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: label '%s' is defined multiple times.\n", __TIME__, line, column, info);
		break;
	}
}
#pragma endregion

//-------------------------------------------------------------------------------------------------------------------

void step1(FILE * stream1, FILE* stream2) {
	char buf[SMALL_SIZE];
	char* word, * next_word = NULL;
	int line_count = 0;
	int lc = 0;
	LABEL_DEF label;
	LINE_DEF line;

	while (fgets(buf, SMALL_SIZE-1, stream1) != NULL) {

		// LABEL
		line_count++;
		line_init(&line);
		char* label_end = strchr(buf, ':');
		if (label_end != NULL) {
			label_end[0] = '\0';
			word = remove_trailing_space(buf);
			BOOL valid = label_valid_name(word);

			label_set(&label, line_count, word - buf, word, (valid ? LABEL_STATUS_VALID : LABEL_STATUS_INVALID), lc);
			int label_adr = label_add(label);
			line.label = label_adr;
		}

		// DIRECTIVE
		word = ((label_end != NULL) ? (label_end + 1) : buf);
		word = remove_trailing_space(word);
		if (word[0] == '.') {
			word = strtok_s(word, " ", &next_word);

			if (_stricmp(word + 1, "ORG") == 0) {
				int value;
				int result = sscanf_s(next_word, "%d", &value);
				if (result == 0) continue; //raise warning

				line.directive = DIRECTIVE_ORG;
				param_set_value(line.params, value);

				lc = value;
			}
			else if (_stricmp(word + 1, "END") == 0) {
				line.directive = DIRECTIVE_END;
				lc += 3;
			}
			else if (_stricmp(word + 1, "DATA") == 0) {
				int value;
				int result = sscanf_s(next_word, "%d", &value);
				if (result == 0) {
					raise_error(line_count, next_word - buf, ERROR_NAN, next_word);
					continue;
				}

				line.directive = DIRECTIVE_DATA;
				param_set_value(line.params, value);

				lc++;
			}
			else {
				raise_error(line_count, word - buf, ERROR_UNKNOWN_DIRECTIVE, word);
				continue;
			}
		}
		// INSTRUCTION
		else {
			if (strlen(word) <= 0)
				continue;

			word = strtok_s(word, " ,\t", &next_word);
			if (word == NULL) continue;

			int i = 0;
			do {
				if (label_valid_name(word) == FALSE)
					raise_error(line_count, word - buf, ERROR_INVALID_LABEL_NAME, NULL);
				param_set_name(line.params + i, word);
				word = strtok_s(next_word, " ,\t", &next_word);
			} while (++i < 3 && word != NULL);
		}

		line_write(line, stream2);
	}

	for (int i = 0; i < labels_count; i++) {
		switch (labels[i].status)
		{
		case LABEL_STATUS_MULTIPLY_DEFINED:
			raise_error(labels[i].line, labels[i].column, ERROR_MULTIPLY_DEFINED_LABEL, labels[i].name);
			break;
		case LABEL_STATUS_INVALID:
			raise_error(labels[i].line, labels[i].column, ERROR_INVALID_LABEL_NAME, labels[i].name);
			break;
		}	
	}
}