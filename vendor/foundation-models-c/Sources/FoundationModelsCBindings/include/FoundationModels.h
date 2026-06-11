/*
 * generated from api/bridge.json; do not edit
 * ABI version: 0.1.0
 */

#ifndef FoundationModels_h
#define FoundationModels_h

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

typedef const void * _Nonnull FMTaskRef;
typedef const void * FMSystemLanguageModelRef;
typedef const void * FMLanguageModelSessionRef;
typedef const void * FMLanguageModelSessionResponseStreamRef;
typedef const void * FMGenerationSchemaRef;
typedef const void * FMGeneratedContentRef;
typedef const void * FMGenerationSchemaPropertyRef;
typedef const void * FMBridgedToolRef;
typedef const void * _Nonnull FMComposedPrompt;

// Callbacks
typedef void (*_Nonnull FMLanguageModelSessionResponseCallback)(int status, const char * _Nullable content, size_t length, void * _Nullable userInfo) __attribute__((swift_attr("@Sendable")));
typedef void (*_Nonnull FMLanguageModelSessionStructuredResponseCallback)(int status, FMGeneratedContentRef _Nullable content, void * _Nullable userInfo) __attribute__((swift_attr("@Sendable")));

typedef enum
{
  FMSystemLanguageModelUnavailableReasonAppleIntelligenceNotEnabled = 0,
  FMSystemLanguageModelUnavailableReasonDeviceNotEligible = 1,
  FMSystemLanguageModelUnavailableReasonModelNotReady = 2,
  FMSystemLanguageModelUnavailableReasonUnknown = 0xFF
} FMSystemLanguageModelUnavailableReason;

typedef enum
{
  FMSystemLanguageModelUseCaseGeneral = 0,
  FMSystemLanguageModelUseCaseContentTagging = 1
} FMSystemLanguageModelUseCase;

typedef enum
{
  FMSystemLanguageModelGuardrailsDefault = 0,
  FMSystemLanguageModelGuardrailsPermissiveContentTransformations = 1
} FMSystemLanguageModelGuardrails;

typedef enum
{
  FMComposedPromptAddImageErrorNone,
  FMComposedPromptAddImageErrorUnsupported,
  FMComposedPromptAddImageErrorUnknown
} FMComposedPromptAddImageError;

// MARK: - SystemLanguageModel

FMSystemLanguageModelRef _Nonnull FMSystemLanguageModelGetDefault(void);
FMSystemLanguageModelRef _Nonnull FMSystemLanguageModelCreate(FMSystemLanguageModelUseCase useCase, FMSystemLanguageModelGuardrails guardrails);
bool FMSystemLanguageModelIsAvailable(FMSystemLanguageModelRef _Nonnull ref, FMSystemLanguageModelUnavailableReason * _Nullable unavailableReason);
// MARK: - LanguageModelSession

FMLanguageModelSessionRef _Nonnull FMLanguageModelSessionCreateDefault(void);
FMLanguageModelSessionRef _Nonnull FMLanguageModelSessionCreateFromSystemLanguageModel(FMSystemLanguageModelRef _Nullable model, const char * _Nullable instructions, FMBridgedToolRef * _Nullable tools, int toolCount);
// MARK: - Prompt construction

FMComposedPrompt _Nonnull FMComposedPromptInitialize(void);
void FMComposedPromptAddText(FMComposedPrompt _Nonnull composedPrompt, const char * _Nonnull text);
bool FMComposedPromptAddImage(FMComposedPrompt _Nonnull composedPrompt, const char * _Nonnull imagePath, FMComposedPromptAddImageError * _Nullable error);
bool FMComposedPromptAddIdentifiedImage(FMComposedPrompt _Nonnull composedPrompt, const char * _Nonnull imagePath, const char * _Nonnull imageIdentifier, FMComposedPromptAddImageError * _Nullable error);
bool FMComposedPromptAddAttachment(FMComposedPrompt _Nonnull composedPrompt, const char * _Nonnull imagePath, const char * _Nullable label, FMComposedPromptAddImageError * _Nullable error);
// MARK: - Response functions

FMLanguageModelSessionRef _Nonnull FMLanguageModelSessionCreateFromTranscript(FMLanguageModelSessionRef _Nonnull transcriptSession, FMSystemLanguageModelRef _Nullable model, FMBridgedToolRef * _Nullable tools, int toolCount);
bool FMLanguageModelSessionIsResponding(FMLanguageModelSessionRef _Nonnull session);
void FMLanguageModelSessionReset(FMLanguageModelSessionRef _Nonnull session);
FMTaskRef _Nonnull FMLanguageModelSessionRespond(FMLanguageModelSessionRef _Nonnull session, FMComposedPrompt _Nonnull composedPrompt, const char * _Nullable optionsJSON, void * _Nullable userInfo, FMLanguageModelSessionResponseCallback callback);
FMLanguageModelSessionResponseStreamRef _Nonnull FMLanguageModelSessionStreamResponse(FMLanguageModelSessionRef _Nonnull session, FMComposedPrompt _Nonnull composedPrompt, const char * _Nullable optionsJSON);
void FMLanguageModelSessionResponseStreamIterate(FMLanguageModelSessionResponseStreamRef _Nonnull stream, void * _Nullable userInfo, FMLanguageModelSessionResponseCallback callback);
FMLanguageModelSessionResponseStreamRef _Nonnull FMLanguageModelSessionStreamResponseWithSchema(FMLanguageModelSessionRef _Nonnull session, FMComposedPrompt _Nonnull composedPrompt, FMGenerationSchemaRef _Nonnull schema, bool includeSchemaInPrompt, const char * _Nullable optionsJSON);
void FMLanguageModelSessionStructuredResponseStreamIterate(FMLanguageModelSessionResponseStreamRef _Nonnull stream, void * _Nullable userInfo, FMLanguageModelSessionResponseCallback callback);
// MARK: - Transcript functions

FMLanguageModelSessionRef _Nullable FMTranscriptCreateFromJSONString(const char * _Nonnull jsonString, int * _Nullable outErrorCode, char * * _Nullable outErrorDescription);
char * _Nullable FMLanguageModelSessionGetTranscriptJSONString(FMLanguageModelSessionRef _Nonnull session, int * _Nullable outErrorCode, char * * _Nullable outErrorDescription);
// MARK: - GenerationSchema functions

FMGenerationSchemaRef _Nonnull FMGenerationSchemaCreate(const char * _Nonnull name, const char * _Nullable description);
FMGenerationSchemaPropertyRef _Nonnull FMGenerationSchemaPropertyCreate(const char * _Nonnull name, const char * _Nullable description, const char * _Nonnull typeName, bool isOptional);
void FMGenerationSchemaPropertyAddAnyOfGuide(FMGenerationSchemaPropertyRef _Nonnull property, const char * * _Nonnull anyOf, int choiceCount, bool wrapped);
void FMGenerationSchemaPropertyAddCountGuide(FMGenerationSchemaPropertyRef _Nonnull property, int count, bool wrapped);
void FMGenerationSchemaPropertyAddMaximumGuide(FMGenerationSchemaPropertyRef _Nonnull property, double maximum, bool wrapped);
void FMGenerationSchemaPropertyAddMinimumGuide(FMGenerationSchemaPropertyRef _Nonnull property, double minimum, bool wrapped);
void FMGenerationSchemaPropertyAddMinItemsGuide(FMGenerationSchemaPropertyRef _Nonnull property, int minItems);
void FMGenerationSchemaPropertyAddMaxItemsGuide(FMGenerationSchemaPropertyRef _Nonnull property, int maxItems);
void FMGenerationSchemaPropertyAddRangeGuide(FMGenerationSchemaPropertyRef _Nonnull property, double minValue, double maxValue, bool wrapped);
void FMGenerationSchemaPropertyAddRegex(FMGenerationSchemaPropertyRef _Nonnull property, const char * _Nonnull pattern, bool wrapped);
void FMGenerationSchemaAddProperty(FMGenerationSchemaRef _Nonnull schema, FMGenerationSchemaPropertyRef _Nonnull property);
void FMGenerationSchemaAddReferenceSchema(FMGenerationSchemaRef _Nonnull schema, FMGenerationSchemaRef _Nonnull referenceSchema);
char * _Nullable FMGenerationSchemaGetJSONString(FMGenerationSchemaRef _Nonnull schema, int * _Nullable outErrorCode, char * * _Nullable outErrorDescription);
// MARK: - GeneratedContent

FMGeneratedContentRef _Nullable FMGeneratedContentCreateFromJSON(const char * _Nonnull jsonString, int * _Nullable outErrorCode, char * * _Nullable outErrorDescription);
char * _Nullable FMGeneratedContentGetJSONString(FMGeneratedContentRef _Nonnull content);
char * _Nullable FMGeneratedContentGetPropertyValue(FMGeneratedContentRef _Nonnull content, const char * _Nonnull propertyName, int * _Nullable outErrorCode, char * * _Nullable outErrorDescription);
bool FMGeneratedContentIsComplete(FMGeneratedContentRef _Nonnull content);
// MARK: - Structured generation session functions

FMTaskRef _Nonnull FMLanguageModelSessionRespondWithSchema(FMLanguageModelSessionRef _Nonnull session, FMComposedPrompt _Nonnull composedPrompt, FMGenerationSchemaRef _Nonnull schema, const char * _Nullable optionsJSON, void * _Nullable userInfo, FMLanguageModelSessionStructuredResponseCallback callback);
FMTaskRef _Nonnull FMLanguageModelSessionRespondWithSchemaFromJSON(FMLanguageModelSessionRef _Nonnull session, FMComposedPrompt _Nonnull composedPrompt, const char * _Nonnull schemaJSONString, const char * _Nullable optionsJSON, void * _Nullable userInfo, FMLanguageModelSessionStructuredResponseCallback callback);
// MARK: - Tools

FMBridgedToolRef _Nullable FMBridgedToolCreate(const char * _Nonnull name, const char * _Nonnull description, FMGenerationSchemaRef _Nonnull parameters, void (* _Nonnull callable)(FMGeneratedContentRef _Nonnull, unsigned int) __attribute__((swift_attr("@Sendable"))), int * _Nullable outErrorCode, char * * _Nullable outErrorDescription);
void FMBridgedToolFinishCall(FMBridgedToolRef _Nonnull tool, unsigned int callId, const char * _Nonnull output);
// MARK: - Memory management

void FMTaskCancel(FMTaskRef _Nonnull task);
void FMRetain(const void * _Nonnull object);
void FMRelease(const void * _Nonnull object);
void FMFreeString(char * _Nullable str);

#endif /* FoundationModels_h */
