#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef const void *FMTaskRef;
typedef const void *FMSystemLanguageModelRef;
typedef const void *FMLanguageModelSessionRef;
typedef const void *FMLanguageModelSessionResponseStreamRef;
typedef const void *FMGenerationSchemaRef;
typedef const void *FMGeneratedContentRef;
typedef const void *FMGenerationSchemaPropertyRef;
typedef const void *FMBridgedToolRef;
typedef const void *FMComposedPromptRef;
typedef enum {
    FMFeedbackSentimentNone = 0,
    FMFeedbackSentimentPositive = 1,
    FMFeedbackSentimentNegative = 2,
    FMFeedbackSentimentNeutral = 3
} FMFeedbackSentiment;

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
extern void FMLanguageModelSessionPrewarm(
    FMLanguageModelSessionRef session, const char *promptPrefix);
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
extern FMLanguageModelSessionResponseStreamRef FMLanguageModelSessionStreamResponseWithSchema(
    FMLanguageModelSessionRef session, FMComposedPromptRef prompt,
    FMGenerationSchemaRef schema, _Bool includeSchemaInPrompt,
    const char *optionsJSON);
extern void FMLanguageModelSessionStructuredResponseStreamIterate(
    FMLanguageModelSessionResponseStreamRef stream, void *userInfo,
    FMLanguageModelSessionResponseCallback callback);
extern char *FMGeneratedContentGetJSONString(FMGeneratedContentRef content);
extern FMBridgedToolRef FMBridgedToolCreate(
    const char *name, const char *description,
    FMGenerationSchemaRef parameters, FMToolCallable callable,
    int *outErrorCode, char **outErrorDescription);
extern void FMRelease(const void *object);
extern void FMFreeString(char *str);
extern char *FMLanguageModelSessionLogFeedbackAttachment(
    FMLanguageModelSessionRef session,
    FMFeedbackSentiment sentiment,
    const char *issuesJSON,
    const char *desiredResponseText,
    size_t *outLength,
    int *outErrorCode,
    char **outErrorDescription);
extern char *FMLanguageModelSessionLogFeedbackAttachmentWithDesiredResponseContent(
    FMLanguageModelSessionRef session,
    FMFeedbackSentiment sentiment,
    const char *issuesJSON,
    const char *desiredResponseContentJSON,
    size_t *outLength,
    int *outErrorCode,
    char **outErrorDescription);

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

/* ===== Pending-tools staging area ===== */
/*
 * MoonBit cannot pass an array of opaque pointers directly via FFI, so we use
 * a two-phase API: callers push tool refs one by one via
 * moonbit_fm_stage_tool(), then pass tool_count when creating the session.
 * The staged array is consumed (cleared) by moonbit_fm_session_create /
 * moonbit_fm_session_create_from_transcript.
 */

#define MOONBIT_FM_MAX_TOOLS 32

static FMBridgedToolRef staged_tools[MOONBIT_FM_MAX_TOOLS];
static int staged_tool_count = 0;

void moonbit_fm_stage_tool(FMBridgedToolRef tool) {
    if (staged_tool_count < MOONBIT_FM_MAX_TOOLS) {
        staged_tools[staged_tool_count++] = tool;
    }
}

static void consume_staged_tools(FMBridgedToolRef **out_tools, int *out_count) {
    *out_tools = staged_tool_count > 0 ? staged_tools : NULL;
    *out_count = staged_tool_count;
    staged_tool_count = 0;
}

/* ===== Session wrappers ===== */

FMLanguageModelSessionRef moonbit_fm_session_create(
    FMSystemLanguageModelRef model,
    const char *instructions,
    int tool_count
) {
    FMBridgedToolRef *tools;
    int count;
    consume_staged_tools(&tools, &count);
    /* tool_count from caller is the expected count; use the staged count. */
    (void)tool_count;
    return FMLanguageModelSessionCreateFromSystemLanguageModel(
        model, instructions, tools, count);
}

FMLanguageModelSessionRef moonbit_fm_session_create_from_transcript(
    FMLanguageModelSessionRef transcript_session,
    FMSystemLanguageModelRef model,
    int tool_count
) {
    FMBridgedToolRef *tools;
    int count;
    consume_staged_tools(&tools, &count);
    (void)tool_count;
    return FMLanguageModelSessionCreateFromTranscript(
        transcript_session, model, tools, count);
}

void moonbit_fm_session_prewarm(
    FMLanguageModelSessionRef session,
    const char *prompt_prefix
) {
    /* MoonBit passes strings as NUL-terminated Bytes and cannot pass NULL;
       an empty prefix means "no prefix". */
    FMLanguageModelSessionPrewarm(
        session,
        (prompt_prefix != NULL && prompt_prefix[0] != '\0') ? prompt_prefix : NULL);
}

static int copy_feedback_attachment_payload(
    char *payload,
    size_t len,
    int code,
    char *desc,
    char *out_content,
    size_t max_len,
    size_t *out_actual_len
) {
    if (payload == NULL) {
        *out_actual_len = 0;
        if (desc != NULL) FMFreeString(desc);
        return code == 0 ? 255 : code;
    }
    *out_actual_len = len;
    if (len <= max_len) {
        memcpy(out_content, payload, len);
    }
    FMFreeString(payload);
    return len <= max_len ? 0 : 255;
}

int moonbit_fm_session_log_feedback_attachment(
    FMLanguageModelSessionRef session,
    int sentiment,
    const char *issues_json,
    const char *desired_response_text,
    char *out_content,
    size_t max_len,
    size_t *out_actual_len
) {
    size_t len = 0;
    int code = 0;
    char *desc = NULL;
    char *payload = FMLanguageModelSessionLogFeedbackAttachment(
        session,
        (FMFeedbackSentiment)sentiment,
        (issues_json != NULL && issues_json[0] != '\0') ? issues_json : NULL,
        (desired_response_text != NULL && desired_response_text[0] != '\0') ? desired_response_text : NULL,
        &len,
        &code,
        &desc);
    return copy_feedback_attachment_payload(
        payload, len, code, desc, out_content, max_len, out_actual_len);
}

int moonbit_fm_session_log_feedback_attachment_with_desired_response_content(
    FMLanguageModelSessionRef session,
    int sentiment,
    const char *issues_json,
    const char *desired_response_content_json,
    char *out_content,
    size_t max_len,
    size_t *out_actual_len
) {
    size_t len = 0;
    int code = 0;
    char *desc = NULL;
    char *payload = FMLanguageModelSessionLogFeedbackAttachmentWithDesiredResponseContent(
        session,
        (FMFeedbackSentiment)sentiment,
        (issues_json != NULL && issues_json[0] != '\0') ? issues_json : NULL,
        (desired_response_content_json != NULL && desired_response_content_json[0] != '\0') ? desired_response_content_json : NULL,
        &len,
        &code,
        &desc);
    return copy_feedback_attachment_payload(
        payload, len, code, desc, out_content, max_len, out_actual_len);
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

/* No pthread and no extra end marker here: the Swift iterate is already
   asynchronous and signals completion itself via a final nil/0 callback,
   which text_response_callback writes as an empty header. */
void moonbit_fm_stream_start_iterate(
    FMLanguageModelSessionResponseStreamRef stream
) {
    FMLanguageModelSessionResponseStreamIterate(
        stream, NULL, text_response_callback);
}

FMLanguageModelSessionResponseStreamRef moonbit_fm_session_stream_response_with_schema(
    FMLanguageModelSessionRef session,
    FMComposedPromptRef prompt,
    FMGenerationSchemaRef schema,
    const char *options_json
) {
    init_response_pipe();
    return FMLanguageModelSessionStreamResponseWithSchema(
        session, prompt, schema, 1, options_json);
}

/* No pthread and no extra end marker here: the Swift iterate is already
   asynchronous and signals completion itself via a final nil/0 callback,
   which text_response_callback writes as an empty header. */
void moonbit_fm_structured_stream_start_iterate(
    FMLanguageModelSessionResponseStreamRef stream
) {
    FMLanguageModelSessionStructuredResponseStreamIterate(
        stream, NULL, text_response_callback);
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

/* ===== CString helpers ===== */

size_t moonbit_fm_cstring_len(const char *s) {
    return s ? strlen(s) : 0;
}

void moonbit_fm_cstring_copy(const char *s, char *buf, size_t max_len) {
    if (!s || max_len == 0) return;
    size_t len = strlen(s);
    size_t to_copy = len < max_len ? len : max_len;
    memcpy(buf, s, to_copy);
}
