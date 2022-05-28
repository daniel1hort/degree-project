#include "core.h"

LABEL_DEF labels[INT16_MAX];
int labels_count;
MACRO_DEF macros[INT16_MAX];
int macros_count;
LINE_DEF lines[INT16_MAX];
int lines_count;
int failed = FALSE;

void raise_error(int line, int column, ERROR_TYPE error, const char* info);
void line_write(LINE_DEF line, FILE* stream);
inline void param_set_name(PARAM_DEF* param, const char* name);
void random_padding_after(char* base, int8_t size, uint32_t seed);

#pragma region LABEL
inline void label_set(LABEL_DEF* label, int line, int column, const char * name, LABEL_SCOPE scope, LABEL_STATUS status, int64_t value) {
	label->location.line = line;
	label->location.column = column;
	strncpy_s(label->name, MAX_LABEL_LENGTH + 1, name, MAX_LABEL_LENGTH);
	label->scope = scope;
	label->status = status;
	label->value = value;
}

int label_add(LABEL_DEF label) {
	for (int i = 0; i < labels_count; i++)
		if (_stricmp(label.name, labels[i].name) == 0) {
			if (labels[i].status == LABEL_STATUS_VALID && label.status == LABEL_STATUS_VALID && labels[i].scope == label.scope) {
				labels[i].status = LABEL_STATUS_MULTIPLY_DEFINED;
			}
			else if (labels[i].status == LABEL_STATUS_UNDEFINED && label.status == LABEL_STATUS_VALID) {
				labels[i].status = LABEL_STATUS_VALID;
				labels[i].value = label.value;
				labels[i].scope = label.scope;
			}
			return i;
		}
	labels[labels_count++] = label;
	return labels_count - 1;
}

int label_get(const char* name, LABEL_SCOPE scope) {
	for (int i = 0; i < labels_count; i++)
		if (_stricmp(labels[i].name, name) == 0 && labels[i].scope == scope)
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

void label_validate_all() {
	for (int i = 0; i < labels_count; i++) {
		switch (labels[i].status)
		{
		case LABEL_STATUS_MULTIPLY_DEFINED:
			raise_error(labels[i].location.line, labels[i].location.column, ERROR_MULTIPLY_DEFINED_LABEL, labels[i].name);
			break;
		case LABEL_STATUS_INVALID:
			raise_error(labels[i].location.line, labels[i].location.column, ERROR_INVALID_SYMBOL_NAME, labels[i].name);
			break;
		case LABEL_STATUS_UNDEFINED:
			raise_error(labels[i].location.line, labels[i].location.column, ERROR_UNDEFINED_SYMBOL, labels[i].name);
			break;
		}
	}
}
#pragma endregion

#pragma region MACRO
inline void macro_set(MACRO_DEF* macro, int line, int column, const char* name) {
	strncpy_s(macro->name, MAX_LABEL_LENGTH + 1, name, MAX_LABEL_LENGTH);
	macro->location.line = line;
	macro->location.column = column;
	macro->first_line = lines_count;
	for (int i = 0; i < 5; i++)
		macro->params[i].status = PARAM_STATUS_EMPTY;
}

int macro_add(MACRO_DEF macro) {
	macros[macros_count++] = macro;
	//TODO: validations
	//assert(0 && "NOT IMPLEMENTED");
}

int macro_get(const char* name) {
	for (int i = macros_count - 1; i >= 0; i--)
		if (_stricmp(macros[i].name, name) == 0)
			return i;
	return -1;
}

int macro_has_parameter(MACRO_DEF macro, const char* name) {
	for (int i = 0; i < 5; i++) {
		PARAM_DEF param = macro.params[i];
		if ((param.status & PARAM_STATUS_NAME) != 0 && _stricmp(param.name, name) == 0)
			return i;
	}
	return -1;
}

int macro_get_parameter_count(MACRO_DEF macro) {
	int count = 0;
	for (int i = 0; i < 5; i++) {
		PARAM_DEF param = macro.params[i];
		if ((param.status & PARAM_STATUS_NAME) != 0)
			count++;
	}
	return count;
}

int macro_expand(int lc, MACRO_DEF macro, PARAM_DEF* params, FILE* stream) {
	int seed = rand();
	int index;
	LABEL_DEF label;
	for (int i = macro.first_line; i < macro.first_line + macro.line_count; i++) {
		LINE_DEF line = lines[i];

		if (line.label != -1) {
			label = labels[line.label];
			random_padding_after(label.name, 4, seed);
			label.value = lc;
			label.scope = LABEL_SCOPE_GLOBAL;
			label_add(label);
		}

		for (int j = 0; j < 3; j++) {
			if ((line.params[j].status & PARAM_STATUS_NAME) == 0)
				continue;

			index = macro_has_parameter(macro, line.params[j].name);
			if (index != -1) {
				param_set_name(line.params + j, params[index].name);
				continue;
			}

			index = label_get(line.params[j].name, LABEL_SCOPE_MACRO);
			if (index != -1 && labels[index].status == LABEL_STATUS_VALID) {
				random_padding_after(line.params[j].name, 4, seed);
				continue;
			}
		}
		if (line.type == LINE_MACRO)
			lc = macro_expand(lc, macros[line.macro], line.params, stream);
		else {
			lc = lc_increase(lc, line);
			line_write(line, stream);
		}
	}
	return lc;
}
#pragma endregion

#pragma region LINE
inline void line_init(LINE_DEF* line) {
	line->directive = DIRECTIVE_NONE;
	line->type = LINE_INSTRUCTION;
	line->label = -1;
	line->params[0].status = PARAM_STATUS_EMPTY;
	line->params[1].status = PARAM_STATUS_EMPTY;
	line->params[2].status = PARAM_STATUS_EMPTY;
}

void line_write(LINE_DEF line, FILE* stream) {
	switch (line.type)
	{
	case LINE_INSTRUCTION:
		fprintf_s(stream, "%s ", line.params[0].name);
		fprintf_s(stream, "%s ", ((line.params[1].status == PARAM_STATUS_EMPTY) ? line.params[0].name : line.params[1].name));
		fprintf_s(stream, "%s ", ((line.params[2].status == PARAM_STATUS_EMPTY) ? "?" : line.params[2].name));
		break;
	case LINE_MACRO:
		return;
		break;
	case LINE_DIRECTIVE:
		switch (line.directive)
		{
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
		break;
	}

	fprintf_s(stream, "\n");
}

void line_parse(LINE_DEF line, int word_size, FILE* stream) {
	int64_t zero_value = 0;

	switch (line.type)
	{
	case LINE_INSTRUCTION:
		for (int i = 0; i < 3; i++) {
			fwrite(&(line.params[i].value), word_size, 1, stream);
		}
		break;
	case LINE_MACRO:
		assert(0 && "NOT IMPLEMENTED");
		break;
	case LINE_DIRECTIVE:
		switch (line.directive)
		{
		case DIRECTIVE_ORG:
			for (int i = line.params[1].value; i < line.params[0].value; i++) {
				fwrite(&zero_value, word_size, 1, stream);
			}
			break;
		case DIRECTIVE_DATA:
			fwrite(&(line.params[0].value), word_size, 1, stream);
			break;
		}
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

int lc_increase(int lc, LINE_DEF line) {
	switch (line.type)
	{
	case LINE_INSTRUCTION:
		return lc + 3;
	case LINE_DIRECTIVE:
		switch (line.directive)
		{
		case DIRECTIVE_DATA:
			return lc + 1;
		case DIRECTIVE_END:
			return lc + 3;
		case DIRECTIVE_ORG:
			return line.params[0].value;
		}
		break;
	}
	return lc;
}

void raise_error(int line, int column, ERROR_TYPE error, const char* info) {
	failed = TRUE;
	switch (error)
	{
	case ERROR_INVALID_DATA_PARAM:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: invalid param '%s' for directive .DATA, it only accepts numbers and valid label names\n", __TIME__, line, column, info);
		break;
	case ERROR_INVALID_SYMBOL_NAME:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: invalid symbol name '%s'. A symbol must start with a letter, may contain digits and must be at most 16 characters long.\n", __TIME__, line, column, info);
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
	case ERROR_MACRO_INSIDE_MACRO:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: cannot declare a macro inside a macro.\n", __TIME__, line, column);
		break;
	case ERROR_ENDM_OUTSIDE_MACRO:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: .ENDM must be preceded by a macro definition.\n", __TIME__, line, column);
		break;
	case ERROR_MACRO_NAME_MISSING:
		fprintf_s(stderr, "[%s] [error] at line %d, column %d: label is mandatory for macro definition.\n", __TIME__, line, column);
		break;
	}
}

const char ALPHANUM_CHARS[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

void random_padding_after(char* base, int8_t size, uint32_t seed) {
	int8_t max = strlen(ALPHANUM_CHARS);
	int8_t start = strlen(base);
	srand(seed);

	for (int i = start; i < start + size; i++) {
		char value = rand() % max;
		strncat_s(base, MAX_LABEL_LENGTH + 1, ALPHANUM_CHARS + value, 1);
	}
}

void symbol_add_ZERO(FILE* stream, int64_t value) {
	LABEL_DEF label;
	LINE_DEF line;

	label_set(&label, 0, 0, "ZERO", LABEL_SCOPE_GLOBAL, LABEL_STATUS_VALID, value);
	label_add(label);
	line_init(&line);
	line.type = LINE_DIRECTIVE;
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
	int line_count = -1;
	int lc = 0;
	BOOL line_has_label;
	BOOL inside_macro_definition = FALSE;
	LABEL_DEF line_label, label;
	LINE_DEF line;
	MACRO_DEF main_macro;
	PARAM_DEF params[5];

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
		line_has_label = FALSE;

		// LABEL
		char* label_end = strchr(buf, ':');
		if (label_end != NULL) {
			label_end[0] = '\0';
			word = remove_trailing_space(buf);
			BOOL valid = label_valid_name(word);

			if (_stricmp(word, "ZERO") == 0)
				raise_error(line_count, word - buf, ERROR_INTERNAL_SYMBOL_REDEFINED, word);

			label_set(&line_label, line_count, word - buf, word,
				(inside_macro_definition? LABEL_SCOPE_MACRO: LABEL_SCOPE_GLOBAL),
				(valid ? LABEL_STATUS_VALID : LABEL_STATUS_INVALID), lc);
			line_has_label = TRUE;
		}

		// DIRECTIVE
		word = ((label_end != NULL) ? (label_end + 1) : buf);
		word = remove_trailing_space(word);
		if (word[0] == '.') {
			line.type = LINE_DIRECTIVE;
			word = strtok_s(word, " \t", &next_word);

			if (_stricmp(word + 1, "ORG") == 0) {
				int value;
				int result = sscanf_s(next_word, "%d", &value);
				if (result == 0) continue; //raise warning

				line.directive = DIRECTIVE_ORG;
				param_set_value(line.params + 0, value);
			}
			else if (_stricmp(word + 1, "END") == 0) {
				line.directive = DIRECTIVE_END;
			}
			else if (_stricmp(word + 1, "DATA") == 0) {
				word = strtok_s(next_word, " \t", &next_word);
				int value;
				int result = sscanf_s(word, "%d", &value);
				if (result == 1) {
					param_set_value(line.params + 0, value);
				}
				else if (label_valid_name(word)) {
					param_set_name(line.params + 0, word);
					label_set(&label, line_count, word - buf, word,
						(inside_macro_definition ? LABEL_SCOPE_MACRO : LABEL_SCOPE_GLOBAL),
						LABEL_STATUS_UNDEFINED, lc);
					label_add(label);
				}
				else {
					raise_error(line_count, next_word - buf, ERROR_INVALID_DATA_PARAM, word);
					continue;
				}
				line.directive = DIRECTIVE_DATA;
			}
			else if (_stricmp(word + 1, "MACRO") == 0) {
				if (inside_macro_definition == TRUE)
					raise_error(line_count, word - buf, ERROR_MACRO_INSIDE_MACRO, NULL);
				if (line_has_label == FALSE)
					raise_error(line_count, word - buf, ERROR_MACRO_NAME_MISSING, NULL);

				macro_set(&main_macro, lines_count, 0, line_label.name);
				word = strtok_s(next_word, " \t", &next_word);
				for (int i = 0; i < 5 && word != NULL; i++) {
					param_set_name(main_macro.params + i, word);
					word = strtok_s(next_word, " \t", &next_word);
				}
				inside_macro_definition = TRUE;
				line_has_label = FALSE;
				line.directive = DIRECTIVE_MACRO;
			}
			else if (_stricmp(word + 1, "ENDM") == 0) {
				if (inside_macro_definition == FALSE)
					raise_error(lines_count, word - buf, ERROR_ENDM_OUTSIDE_MACRO, NULL);

				main_macro.line_count = lines_count - main_macro.first_line;
				macro_add(main_macro);
				inside_macro_definition = FALSE;
				line.directive = DIRECTIVE_ENDM;
			}
			else {
				raise_error(line_count, word - buf, ERROR_UNKNOWN_DIRECTIVE, word);
				continue;
			}
		}
		// MACRO
		else if (word[0] == '@') {
			word = strtok_s(word, " \t", &next_word);
			int macro_adr = macro_get(word + 1);
			if (macro_adr == -1)
				raise_error(line_count, word - buf, ERROR_UNDEFINED_SYMBOL, word);

			memset(params, 0, sizeof(PARAM_DEF) * 5);
			word = strtok_s(next_word, " \t", &next_word);
			for (int i = 0; i < 5 && word != NULL; i++) {
				BOOL valid = label_valid_name(word);
				if (_stricmp(word, "*") != 0 && _stricmp(word, "?") != 0 &&
					(inside_macro_definition == FALSE || inside_macro_definition == TRUE && macro_has_parameter(main_macro, word) == -1)) {
					label_set(&label, line_count, word - buf, word,
						(inside_macro_definition ? LABEL_SCOPE_MACRO : LABEL_SCOPE_GLOBAL),
						(valid ? LABEL_STATUS_UNDEFINED : LABEL_STATUS_INVALID), lc);
					label_add(label);
				}
				param_set_name((inside_macro_definition ? (line.params + i) : (params + i)), word);
				word = strtok_s(next_word, " \t", &next_word);
			}

			line.type = LINE_MACRO;
			if (inside_macro_definition) {
				line.macro = macro_adr;
			}
			else {
				lc = macro_expand(lc, macros[macro_adr], params, stream2);
			}
		}
		// INSTRUCTION
		else {
			line.type = LINE_INSTRUCTION;
			if (strlen(word) <= 0)
			{
				if (line_has_label)
					line.label = label_add(line_label);
				continue;
			}

			word = strtok_s(word, " ,\t", &next_word);
			if (word == NULL) continue;

			int i = 0;
			do {
				BOOL valid = label_valid_name(word);
				if (_stricmp(word, "*") != 0 && _stricmp(word, "?") != 0 &&
					(inside_macro_definition == FALSE || inside_macro_definition == TRUE && macro_has_parameter(main_macro, word) == -1)) {
					label_set(&label, line_count, word - buf, word,
						(inside_macro_definition ? LABEL_SCOPE_MACRO : LABEL_SCOPE_GLOBAL),
						(valid ? LABEL_STATUS_UNDEFINED : LABEL_STATUS_INVALID), lc);
					label_add(label);
				}

				param_set_name(line.params + i, word);
				word = strtok_s(next_word, " ,\t", &next_word);
			} while (++i < 3 && word != NULL);

			if (!symbol_enforce_ZERO(line))
				raise_error(line_count, 0, ERROR_SYMBOL_ZERO_READONLY, NULL);
		}

		if (line_has_label == TRUE)
			line.label = label_add(line_label);
		if (inside_macro_definition == FALSE)
			lc = lc_increase(lc, line);

		if (inside_macro_definition == TRUE && (line.type != LINE_DIRECTIVE || line.directive != DIRECTIVE_MACRO))
			lines[lines_count++] = line;
		if(inside_macro_definition == FALSE && (line.type != LINE_DIRECTIVE || line.directive != DIRECTIVE_ENDM))
			line_write(line, stream2);
	}

	symbol_add_ZERO(stream2, lc);
	label_validate_all();

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
			line.type = LINE_DIRECTIVE;
			word = strtok_s(buf, " \t", &next_word);
			if (_stricmp(word + 1, "ORG") == 0) {
				word = remove_trailing_space(next_word);
				int value;
				sscanf_s(word, "%d", &value);

				line.directive = DIRECTIVE_ORG;
				param_set_value(line.params + 0, value);
				param_set_value(line.params + 1, lc);
			}
			else if (_stricmp(word + 1, "END") == 0) {
				line.directive = DIRECTIVE_END;
			}
			else if (_stricmp(word + 1, "DATA") == 0) {
				word = remove_trailing_space(next_word);
				int value;
				int result = sscanf_s(word, "%d", &value);
				if (result == 1) {
					param_set_value(line.params + 0, value);
				}
				else {
					value = labels[label_get(word, LABEL_SCOPE_GLOBAL)].value;
					param_set_value(line.params + 0, value);
				}
				line.directive = DIRECTIVE_DATA;
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
					value = labels[label_get(word, LABEL_SCOPE_GLOBAL)].value;
				param_set_value(line.params + i, value);
			}
		}

		lc = lc_increase(lc, line);
		line_parse(line, word_size, stream2);
	}

	//Fill the file with 0 until size
	line_init(&line);
	line.type = LINE_DIRECTIVE;
	line.directive = DIRECTIVE_ORG;
	param_set_value(line.params + 0, file_size - 1);
	line_parse(line, word_size, stream2);
}