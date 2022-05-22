#include "core.h"

LABEL_DEF labels[INT16_MAX];
int labels_count;
int failed = FALSE;

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
			if (labels[i].status == LABEL_STATUS_VALID && label.status == LABEL_STATUS_VALID) {
				labels[i].status = LABEL_STATUS_MULTIPLY_DEFINED;
			}
			else if (labels[i].status == LABEL_STATUS_UNDEFINED && label.status == LABEL_STATUS_VALID) {
				labels[i].status = LABEL_STATUS_VALID;
				labels[i].value = label.value;
			}
			return i;
		}
	labels[labels_count++] = label;
	return labels_count - 1;
}

int label_get(const char* name) {
	for (int i = 0; i < labels_count; i++)
		if (_stricmp(labels[i].name, name) == 0)
			return i;
	return -1;
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

#pragma region LINE
inline void line_init(LINE_DEF* line) {
	line->directive = DIRECTIVE_NONE;
	line->label = -1;
	line->params[0].status = PARAM_STATUS_EMPTY;
	line->params[1].status = PARAM_STATUS_EMPTY;
	line->params[2].status = PARAM_STATUS_EMPTY;
}

void line_write(LINE_DEF line, FILE* stream) {
	switch (line.directive)
	{
	case DIRECTIVE_NONE:
		fprintf_s(stream, "%s ", line.params[0].name);
		fprintf_s(stream, "%s ", ((line.params[1].status == PARAM_STATUS_EMPTY) ? line.params[0].name : line.params[1].name));
		fprintf_s(stream, "%s ", ((line.params[2].status == PARAM_STATUS_EMPTY) ? "?" : line.params[2].name));
		break;
	case DIRECTIVE_ORG:
		fprintf_s(stream, ".ORG %lld", line.params[0].value);
		break;
	case DIRECTIVE_END:
		fprintf_s(stream, "ZERO ZERO *");
		break;
	case DIRECTIVE_DATA:
		if ((line.params[0].status & PARAM_STATUS_VALUE) != 0)
			fprintf_s(stream, ".DATA %lld", line.params[0].value);
		else
			fprintf_s(stream, ".DATA %s", line.params[0].name);
		break;
	}
	fprintf_s(stream, "\n");
}

void line_parse(LINE_DEF line, int word_size, FILE* stream) {
	int64_t zero_value = 0;

	switch (line.directive)
	{
	case DIRECTIVE_NONE:
		for (int i = 0; i < 3; i++) {
			fwrite(&(line.params[i].value), word_size , 1, stream);
		}
		break;
	case DIRECTIVE_ORG:
		for (int i = line.params[1].value; i < line.params[0].value; i++) {
			fwrite(&zero_value, word_size, 1, stream);
		}
		break;
	case DIRECTIVE_END:
		break;
	case DIRECTIVE_DATA:
		fwrite(&(line.params[0].value), word_size, 1, stream);
		break;
	}
}

inline void param_set_value(PARAM_DEF* param, uint64_t value) {
	param->status |= PARAM_STATUS_VALUE;
	param->value = value;
}

inline void param_set_name(PARAM_DEF* param, const char* name) {
	param->status |= PARAM_STATUS_NAME;
	strcpy_s(param->name, MAX_LABEL_LENGTH + 1, name);
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

void raise_error(int line, int column, ERROR_TYPE error, const char* info) {
	failed = TRUE;
	switch (error)
	{
	case ERROR_INVALID_DATA_PARAM:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: invalid param '%s' for directive .DATA, it only accepts numbers and valid label names\n", __TIME__, line, column, info);
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
	case ERROR_UNDEFINED_SYMBOL:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: symbol '%s' is undefined.\n", __TIME__, line, column, info);
		break;
	case ERROR_INTERNAL_SYMBOL_REDEFINED:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: symbol '%s' is handled by the assembler.\n", __TIME__, line, column, info);
		break;
	case ERROR_SYMBOL_ZERO_READONLY:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: symbol 'ZERO' is read-only.\n", __TIME__, line, column);
		break;
	}
}

void symbol_add_ZERO(FILE* stream, int64_t value) {
	LABEL_DEF label;
	LINE_DEF line;

	label_set(&label, 0, 0, "ZERO", LABEL_STATUS_VALID, value);
	label_add(label);
	line_init(&line);
	line.directive = DIRECTIVE_DATA;
	param_set_value(line.params + 0, 0);
	line_write(line, stream);
}

BOOL symbol_enforce_ZERO(LINE_DEF line) {
	return _stricmp(line.params[0].name, "ZERO") == 0 || _stricmp(line.params[1].name, "ZERO") != 0;
}
#pragma endregion

//-------------------------------------------------------------------------------------------------------------------

void step1(FILE* stream1, FILE* stream2) {
	char buf[SMALL_SIZE + 1], discard[SMALL_SIZE + 1];
	char* word, * next_word = NULL;
	int line_count = 0;
	int lc = 0;
	LABEL_DEF label;
	LINE_DEF line;

	while (fgets(buf, SMALL_SIZE - 1, stream1) != NULL) {

#pragma region DISCARD
		char* discard_result;
		if (buf[strlen(buf) - 1] != '\n') {
			do {
				discard_result = fgets(discard, SMALL_SIZE - 1, stream1);
			} while (discard[strlen(discard) - 1] != '\n' && discard_result != NULL);
		}
#pragma endregion

		// COMMENTS
		char* comment_start = strchr(buf, ';');
		if (comment_start != NULL) {
			memset(comment_start, 0, strlen(comment_start));
		}

		line_count++;
		line_init(&line);

		// LABEL
		char* label_end = strchr(buf, ':');
		if (label_end != NULL) {
			label_end[0] = '\0';
			word = remove_trailing_space(buf);
			BOOL valid = label_valid_name(word);

			if (_stricmp(word, "ZERO") == 0)
				raise_error(line_count, word - buf, ERROR_INTERNAL_SYMBOL_REDEFINED, word);

			label_set(&label, line_count, word - buf, word, (valid ? LABEL_STATUS_VALID : LABEL_STATUS_INVALID), lc);
			int label_adr = label_add(label);
			line.label = label_adr;
		}

		// DIRECTIVE
		word = ((label_end != NULL) ? (label_end + 1) : buf);
		word = remove_trailing_space(word);
		if (word[0] == '.') {
			word = strtok_s(word, " \t", &next_word);

			if (_stricmp(word + 1, "ORG") == 0) {
				int value;
				int result = sscanf_s(next_word, "%d", &value);
				if (result == 0) continue; //raise warning

				line.directive = DIRECTIVE_ORG;
				param_set_value(line.params + 0, value);

				lc = value;
			}
			else if (_stricmp(word + 1, "END") == 0) {
				line.directive = DIRECTIVE_END;
				lc += 3;
			}
			else if (_stricmp(word + 1, "DATA") == 0) {
				word = strtok_s(next_word, " \t", &next_word);
				int value;
				int result = sscanf_s(word, "%d", &value);
				if (result == 1) {
					param_set_value(line.params + 0, value);
				}
				else if(label_valid_name(word)) {
					param_set_name(line.params + 0, word);
					label_set(&label, line_count, word - buf, word, LABEL_STATUS_UNDEFINED, lc);
					label_add(label);
				}
				else {
					raise_error(line_count, next_word - buf, ERROR_INVALID_DATA_PARAM, word);
					continue;
				}

				line.directive = DIRECTIVE_DATA;
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
				BOOL valid = label_valid_name(word);
				if (_stricmp(word, "*") != 0 && _stricmp(word, "?") != 0) { //exclude those symbols
					label_set(&label, line_count, word - buf, word, (valid ? LABEL_STATUS_UNDEFINED : LABEL_STATUS_INVALID), lc);
					label_add(label);
				}

				param_set_name(line.params + i, word);
				word = strtok_s(next_word, " ,\t", &next_word);
			} while (++i < 3 && word != NULL);

			if (!symbol_enforce_ZERO(line))
				raise_error(line_count, 0, ERROR_SYMBOL_ZERO_READONLY, NULL);

			lc += 3;
		}

		line_write(line, stream2);
	}

	symbol_add_ZERO(stream2, lc);

	for (int i = 0; i < labels_count; i++) {
		switch (labels[i].status)
		{
		case LABEL_STATUS_MULTIPLY_DEFINED:
			raise_error(labels[i].line, labels[i].column, ERROR_MULTIPLY_DEFINED_LABEL, labels[i].name);
			break;
		case LABEL_STATUS_INVALID:
			raise_error(labels[i].line, labels[i].column, ERROR_INVALID_LABEL_NAME, labels[i].name);
			break;
		case LABEL_STATUS_UNDEFINED:
			raise_error(labels[i].line, labels[i].column, ERROR_UNDEFINED_SYMBOL, labels[i].name);
			break;
		}	
	}

	if (failed == TRUE)
		exit(EXIT_FAILURE);
}

void step2(FILE* stream1, FILE* stream2, int file_size, int word_size) {
	char buf[SMALL_SIZE + 1];
	char* word, * next_word = NULL;
	int line_count = 0;
	int lc = 0;
	LINE_DEF line;

	while (fgets(buf, SMALL_SIZE - 1, stream1) != NULL) {

		line_count++;
		line_init(&line);

		//DIRECTIVE
		if (buf[0] == '.') {
			word = strtok_s(buf, " \t", &next_word);
			if (_stricmp(word + 1, "ORG") == 0) {
				word = remove_trailing_space(next_word);
				int value;
				sscanf_s(word, "%d", &value);

				line.directive = DIRECTIVE_ORG;
				param_set_value(line.params + 0, value);
				param_set_value(line.params + 1, lc);
				lc = value;
			}
			else if (_stricmp(word + 1, "END") == 0) {
				line.directive = DIRECTIVE_END;
				lc += 3;
			}
			else if (_stricmp(word + 1, "DATA") == 0) {
				word = remove_trailing_space(next_word);
				int value;
				int result = sscanf_s(word, "%d", &value);
				if (result == 1) {
					param_set_value(line.params + 0, value);
				}
				else {
					value = labels[label_get(word)].value;
					param_set_value(line.params + 0, value);
				}
				line.directive = DIRECTIVE_DATA;
				
				lc++;
			}
		}
		//INSTRUCTION
		else {
			next_word = remove_trailing_space(buf);
			for (int i = 0; i < 3; i++) {
				word = strtok_s(next_word, " ,\t", &next_word);

				int64_t value = 0;
				if (_stricmp(word, "*") == 0)
					value = lc;
				else if (_stricmp(word, "?") == 0)
					value = lc + 3;
				else
					value = labels[label_get(word)].value;
				param_set_value(line.params + i, value);
			}

			lc += 3;
		}

		line_parse(line, word_size, stream2);
	}

	//Fill the file with 0 until size
	line_init(&line);
	line.directive = DIRECTIVE_ORG;
	param_set_value(line.params + 0, file_size - 1);
	line_parse(line, word_size, stream2);
}