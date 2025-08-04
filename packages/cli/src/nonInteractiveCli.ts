/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import {
  Config,
  ToolCallRequestInfo,
  executeToolCall,
  ToolRegistry,
  shutdownTelemetry,
  isTelemetrySdkInitialized,
  GeminiEventType,
  ToolErrorType,
} from '@google/gemini-cli-core';
import {
  Content,
  Part,
  FunctionCall,
  PartListUnion,
} from '@google/genai';

import { parseAndFormatApiError } from './ui/utils/errorParsing.js';
import { handleAtCommand } from './ui/hooks/atCommandProcessor.js';
import { isAtCommand } from './ui/utils/commandUtils.js';

export async function runNonInteractive(
  config: Config,
  input: string,
  prompt_id: string,
): Promise<void> {
  await config.initialize();
  // Handle EPIPE errors when the output is piped to a command that closes early.
  process.stdout.on('error', (err: NodeJS.ErrnoException) => {
    if (err.code === 'EPIPE') {
      // Exit gracefully if the pipe is closed.
      process.exit(0);
    }
  });

  const geminiClient = config.getGeminiClient();
  const toolRegistry: ToolRegistry = await config.getToolRegistry();

  const abortController = new AbortController();
  
  // Process @file commands
  let processedInput: string | PartListUnion = input;
  if (isAtCommand(input)) {
    const atCommandResult = await handleAtCommand({
      query: input,
      config,
      addItem: (..._args: any[]) => Date.now(), // Non-interactive mode timestamp
      onDebugMessage: () => {}, // No debug messages in non-interactive mode
      messageId: Date.now(),
      signal: abortController.signal,
    });

    if (atCommandResult.processedQuery) {
      processedInput = atCommandResult.processedQuery;
    }
  }

  // Convert processedInput to Part[]
  let parts: Part[];
  if (typeof processedInput === 'string') {
    parts = [{ text: processedInput }];
  } else if (Array.isArray(processedInput)) {
    parts = processedInput.map((p) =>
      typeof p === 'string' ? { text: p } : p
    );
  } else {
    parts = [
      typeof processedInput === 'string'
        ? { text: processedInput }
        : processedInput,
    ];
  }

  let currentMessages: Content[] = [{ role: 'user', parts }];
  let turnCount = 0;
  try {
    while (true) {
      turnCount++;
      if (
        config.getMaxSessionTurns() >= 0 &&
        turnCount > config.getMaxSessionTurns()
      ) {
        console.error(
          '\n Reached max session turns for this session. Increase the number of turns by specifying maxSessionTurns in settings.json.',
        );
        return;
      }
      const functionCalls: FunctionCall[] = [];

      const responseStream = geminiClient.sendMessageStream(
        currentMessages[0]?.parts || [],
        abortController.signal,
        prompt_id,
      );

      for await (const event of responseStream) {
        if (abortController.signal.aborted) {
          console.error('Operation cancelled.');
          return;
        }

        if (event.type === GeminiEventType.Content) {
          process.stdout.write(event.value);
        } else if (event.type === GeminiEventType.ToolCallRequest) {
          const toolCallRequest = event.value;
          const fc: FunctionCall = {
            name: toolCallRequest.name,
            args: toolCallRequest.args,
            id: toolCallRequest.callId,
          };
          functionCalls.push(fc);
        }
      }

      if (functionCalls.length > 0) {
        const toolResponseParts: Part[] = [];

        for (const fc of functionCalls) {
          const callId = fc.id ?? `${fc.name}-${Date.now()}`;
          const requestInfo: ToolCallRequestInfo = {
            callId,
            name: fc.name as string,
            args: (fc.args ?? {}) as Record<string, unknown>,
            isClientInitiated: false,
            prompt_id,
          };

          const toolResponse = await executeToolCall(
            config,
            requestInfo,
            toolRegistry,
            abortController.signal,
          );

          if (toolResponse.error) {
            console.error(
              `Error executing tool ${fc.name}: ${toolResponse.resultDisplay || toolResponse.error.message}`,
            );
            if (toolResponse.errorType === ToolErrorType.UNHANDLED_EXCEPTION)
              process.exit(1);
          }

          if (toolResponse.responseParts) {
            const parts = Array.isArray(toolResponse.responseParts)
              ? toolResponse.responseParts
              : [toolResponse.responseParts];
            for (const part of parts) {
              if (typeof part === 'string') {
                toolResponseParts.push({ text: part });
              } else if (part) {
                toolResponseParts.push(part);
              }
            }
          }
        }
        currentMessages = [{ role: 'user', parts: toolResponseParts }];
      } else {
        process.stdout.write('\n'); // Ensure a final newline
        return;
      }
    }
  } catch (error) {
    console.error(
      parseAndFormatApiError(
        error,
        config.getContentGeneratorConfig()?.authType,
      ),
    );
    process.exit(1);
  } finally {
    if (isTelemetrySdkInitialized()) {
      await shutdownTelemetry();
    }
  }
}
