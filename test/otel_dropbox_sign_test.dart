// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_dropbox_sign/otel_dropbox_sign.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_dropbox_sign-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('send records signer_count + test_mode + qualified', () async {
    await tracedDropboxSign<String>(
      operation: 'signature_request.send',
      invoke: () async => const DropboxSignCallResult(
        value: 'ok',
        result: DropboxSignResult(
          signatureRequestId: 'sr-1',
          testMode: false,
          embedded: false,
          signerCount: 2,
          signedCount: 0,
          complete: false,
          qualifiedSignature: true,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('dropbox_sign signature_request.send')!,
    );
    expect(a['dropbox_sign.signature_request.id'], 'sr-1');
    expect(a['dropbox_sign.signer_count'], 2);
    expect(a['dropbox_sign.qualified_signature'], true);
    expect(a['dropbox_sign.test_mode'], false);
  });

  test('declined request sets span error', () async {
    await tracedDropboxSign<String>(
      operation: 'signature_request.get',
      invoke: () async => const DropboxSignCallResult(
        value: 'ok',
        result: DropboxSignResult(declined: true),
      ),
    );
    expect(
      spans.findSpanByName('dropbox_sign signature_request.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutDropboxSignInstrumentationAsync(() async {
      await tracedDropboxSign<String>(
        operation: 'signature_request.list',
        invoke: () async => const DropboxSignCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('dropbox_sign '), isEmpty);
  });
}
