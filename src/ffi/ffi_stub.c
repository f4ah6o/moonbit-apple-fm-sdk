#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

typedef const void *FMTaskRef;
typedef const void *FMSystemLanguageModelRef;
typedef const void *FMLanguageModelSessionRef;
typedef const void *FMLanguageModelSessionResponseStreamRef;
typedef const void *FMGenerationSchemaRef;
typedef const void *FMGeneratedContentRef;
typedef const void *FMGenerationSchemaPropertyRef;
typedef const void *FMBridgedToolRef;
typedef const void *FMComposedPromptRef;

typedef void (*FMLanguageModelSessionResponseCallback)(
    int status, const char *content, size_t length, void *userInfo);
typedef void (*FMLanguageModelSessionStructuredResponseCallback)(
    int status, FMGeneratedContentRef content, void *userInfo);
typedef void (*FMToolCallable)(FMGeneratedContentRef, unsigned int);

extern void FMGenerationSchemaPropertyAddAnyOfGuide(
    FMGenerationSchemaPropertyRef property,
    const char **anyOf, int choiceCount, _Bool wrapped);
extern FMLanguageModelSessionRef FMLanguageModelSessionCreateFromSystemLanguageModel(
    FMSystemLanguageModelRef model, const char *instructions,
    FMBridgedToolRef *tools, int toolCount);
extern FMLanguageModelSessionRef FMLanguageModelSessionCreateFromTranscript(
    FMLanguageModelSessionRef transcriptSession, FMSystemLanguageModelRef model,
    FMBridgedToolRef *tools, int toolCount);
extern FMTaskRef FMLanguageModelSessionRespond(
    FMLanguageModelSessionRef session, FMComposedPromptRef prompt,
    const char *optionsJSON, void *userInfo,
    FMLanguageModelSessionResponseCallback callback);
extern FMTaskRef FMLanguageModelSessionRespondWithSchema(
    FMLanguageModelSessionRef session, FMComposedPromptRef prompt,
    FMGenerationSchemaRef schema, const char *optionsJSON,
    void *userInfo, FMLanguageModelSessionStructuredResponseCallback callback);
extern FMTaskRef FMLanguageModelSessionRespondWithSchemaFromJSON(
    FMLanguageModelSessionRef session, FMComposedPromptRef prompt,
    const char *schemaJSONString, const char *optionsJSON,
    void *userInfo, FMLanguageModelSessionStructuredResponseCallback callback);
extern FMLanguageModelSessionResponseStreamRef FMLanguageModelSessionStreamResponse(
    FMLanguageModelSessionRef session, FMComposedPromptRef prompt,
    const char *optionsJSON);
extern void FMLanguageModelSessionResponseStreamIterate(
    FMLanguageModelSessionResponseStreamRef stream, void *userInfo,
    FMLanguageModelSessionResponseCallback callback);
extern char *FMGeneratedContentGetJSONString(FMGeneratedContentRef content);
extern FMBridgedToolRef FMBridgedToolCreate(
    const char *name, const char *description,
    FMGenerationSchemaRef parameters, FMToolCallable callable,
    int *outErrorCode, char **outErrorDescription);
extern void FMRelease(const void *object);

/* ===== anyOf helper ===== */

void moonbit_fm_property_add_any_of_guide(
    FMGenerationSchemaPropertyRef property,
    const char *packed_strings,
    int choice_count,
    _Bool wrapped
) {
    const char **ptrs = (const char **)malloc(sizeof(const char *) * choice_count);
    const char *p = packed_strings;
    for (int i = 0; i < choice_count; i++) {
        ptrs[i] = p;
        p += strlen(p) + 1;
    }
    FMGenerationSchemaPropertyAddAnyOfGuide(property, ptrs, choice_count, wrapped);
    free(ptrs);
}

/* ===== Pipe-based callback bridge ===== */

typedef struct {
    int status;
    size_t length;
} CallbackHeader;

static int response_pipe[2] = {-1, -1};

static void init_response_pipe(void) {
    if (response_pipe[0] >= 0) return;
    pipe(response_pipe);
}

static void cleanup_response_pipe(void) {
    if (response_pipe[0] >= 0) { close(response_pipe[0]); close(response_pipe[1]); }
    response_pipe[0] = response_pipe[1] = -1;
}

static void text_response_callback(int status, const char *content, size_t length, void *userInfo) {
    CallbackHeader hdr = { .status = status, .length = length };
    write(response_pipe[1], &hdr, sizeof(hdr));
    if (content && length > 0) {
        write(response_pipe[1], content, length);
    }
}

static void structured_response_callback(int status, FMGeneratedContentRef content, void *userInfo) {
    if (status != 0 || !content) {
        CallbackHeader hdr = { .status = status, .length = 0 };
        write(response_pipe[1], &hdr, sizeof(hdr));
        return;
    }
    char *json = FMGeneratedContentGetJSONString(content);
    size_t len = json ? strlen(json) : 0;
    CallbackHeader hdr = { .status = status, .length = len };
    write(response_pipe[1], &hdr, sizeof(hdr));
    if (json && len > 0) {
        write(response_pipe[1], json, len);
    }
}

/* MoonBit-callable: blocking read of one response from pipe.
   Returns status. Writes content into caller-provided buffer.
   out_content must be pre-allocated by caller (max_len bytes).
   out_actual_len receives the actual content length. */
int moonbit_fm_read_response(char *out_content, size_t max_len, size_t *out_actual_len) {
    CallbackHeader hdr;
    ssize_t n = read(response_pipe[0], &hdr, sizeof(hdr));
    if (n != sizeof(hdr)) return -1;
    *out_actual_len = hdr.length;
    if (hdr.length > 0) {
        size_t to_read = hdr.length < max_len ? hdr.length : max_len;
        read(response_pipe[0], out_content, to_read);
        if (hdr.length > max_len) {
            char discard[256];
            size_t remaining = hdr.length - max_len;
            while (remaining > 0) {
                size_t chunk = remaining < 256 ? remaining : 256;
                read(response_pipe[0], discard, chunk);
                remaining -= chunk;
            }
        }
    }
    return hdr.status;
}

/* ===== Session wrappers ===== */

FMLanguageModelSessionRef moonbit_fm_session_create(
    FMSystemLanguageModelRef model,
    const char *instructions,
    int tool_count
) {
    return FMLanguageModelSessionCreateFromSystemLanguageModel(
        model, instructions, NULL, tool_count);
}

FMTaskRef moonbit_fm_session_respond(
    FMLanguageModelSessionRef session,
    FMComposedPromptRef prompt,
    const char *options_json
) {
    init_response_pipe();
    return FMLanguageModelSessionRespond(
        session, prompt, options_json, NULL, text_response_callback);
}

FMTaskRef moonbit_fm_session_respond_with_schema(
    FMLanguageModelSessionRef session,
    FMComposedPromptRef prompt,
    FMGenerationSchemaRef schema,
    const char *options_json
) {
    init_response_pipe();
    return FMLanguageModelSessionRespondWithSchema(
        session, prompt, schema, options_json, NULL, structured_response_callback);
}

FMTaskRef moonbit_fm_session_respond_with_json_schema(
    FMLanguageModelSessionRef session,
    FMComposedPromptRef prompt,
    const char *schema_json,
    const char *options_json
) {
    init_response_pipe();
    return FMLanguageModelSessionRespondWithSchemaFromJSON(
        session, prompt, schema_json, options_json, NULL, structured_response_callback);
}

/* ===== Streaming wrapper ===== */

FMLanguageModelSessionResponseStreamRef moonbit_fm_session_stream_response(
    FMLanguageModelSessionRef session,
    FMComposedPromptRef prompt,
    const char *options_json
) {
    init_response_pipe();
    return FMLanguageModelSessionStreamResponse(session, prompt, options_json);
}

typedef struct {
    FMLanguageModelSessionResponseStreamRef stream;
} StreamIterateArgs;

static void *stream_iterate_thread(void *arg) {
    StreamIterateArgs *args = (StreamIterateArgs *)arg;
    FMLanguageModelSessionResponseStreamIterate(
        args->stream, NULL, text_response_callback);
    CallbackHeader end = { .status = 0, .length = 0 };
    write(response_pipe[1], &end, sizeof(end));
    free(args);
    return NULL;
}

void moonbit_fm_stream_start_iterate(
    FMLanguageModelSessionResponseStreamRef stream
) {
    StreamIterateArgs *args = malloc(sizeof(StreamIterateArgs));
    args->stream = stream;
    pthread_t thread;
    pthread_create(&thread, NULL, stream_iterate_thread, args);
    pthread_detach(thread);
}

void moonbit_fm_cleanup_pipe(void) {
    cleanup_response_pipe();
}

/* ===== Tool bridge ===== */

static int tool_pipe[2] = {-1, -1};

typedef struct {
    unsigned int call_id;
    size_t json_length;
} ToolCallHeader;

static void tool_callable(FMGeneratedContentRef content, unsigned int callId) {
    if (tool_pipe[0] < 0) return;
    char *json = FMGeneratedContentGetJSONString(content);
    size_t len = json ? strlen(json) : 0;
    ToolCallHeader hdr = { .call_id = callId, .json_length = len };
    write(tool_pipe[1], &hdr, sizeof(hdr));
    if (json && len > 0) {
        write(tool_pipe[1], json, len);
    }
}

FMBridgedToolRef moonbit_fm_tool_create(
    const char *name,
    const char *description,
    FMGenerationSchemaRef parameters,
    int *out_error_code,
    char **out_error_description
) {
    if (tool_pipe[0] < 0) pipe(tool_pipe);
    return FMBridgedToolCreate(
        name, description, parameters, tool_callable,
        out_error_code, out_error_description);
}

int moonbit_fm_tool_read_call(
    unsigned int *out_call_id,
    char *out_json, size_t max_len, size_t *out_actual_len
) {
    ToolCallHeader hdr;
    ssize_t n = read(tool_pipe[0], &hdr, sizeof(hdr));
    if (n != (ssize_t)sizeof(hdr)) return -1;
    *out_call_id = hdr.call_id;
    *out_actual_len = hdr.json_length;
    if (hdr.json_length > 0) {
        size_t to_read = hdr.json_length < max_len ? hdr.json_length : max_len;
        read(tool_pipe[0], out_json, to_read);
        if (hdr.json_length > max_len) {
            char discard[256];
            size_t remaining = hdr.json_length - max_len;
            while (remaining > 0) {
                size_t chunk = remaining < 256 ? remaining : 256;
                read(tool_pipe[0], discard, chunk);
                remaining -= chunk;
            }
        }
    }
    return 0;
}

void moonbit_fm_tool_cleanup(void) {
    if (tool_pipe[0] >= 0) { close(tool_pipe[0]); close(tool_pipe[1]); }
    tool_pipe[0] = tool_pipe[1] = -1;
}
