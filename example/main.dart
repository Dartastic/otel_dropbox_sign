// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_dropbox_sign/otel_dropbox_sign.dart';

/// Traces Dropbox Sign calls with OpenTelemetry.
///
/// `otel_dropbox_sign` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Dropbox Sign call in
/// [tracedDropboxSign]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'dropbox-sign-example');

  // Wraps a Dropbox Sign API call in a CLIENT span.
  final dropboxSignId = await tracedDropboxSign<String>(
    operation: 'signature_request.create_embedded',
    invoke: () async {
      // Make the Dropbox Sign call here, then report what it returned.
      const id = 'dropbox_sign_8f3a2c';
      return const DropboxSignCallResult(
          value: id,
          result: DropboxSignResult(
              itemCount: 3,
              numPages: 1,
              signatureRequestId: 'signature_request_id',
              testMode: true,
              embedded: true,
              signerCount: 3,
              signedCount: 3,
              complete: true,
              declined: true,
              qualifiedSignature: true,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info(
      'tracedDropboxSign signature_request.create_embedded returned $dropboxSignId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutDropboxSignInstrumentationAsync.
  await runWithoutDropboxSignInstrumentationAsync(
    () => tracedDropboxSign<String>(
      operation: 'signature_request.create_embedded',
      invoke: () async {
        const id = 'dropbox_sign_8f3a2c';
        return const DropboxSignCallResult(
            value: id,
            result: DropboxSignResult(
                itemCount: 3,
                numPages: 1,
                signatureRequestId: 'signature_request_id',
                testMode: true,
                embedded: true,
                signerCount: 3,
                signedCount: 3,
                complete: true,
                declined: true,
                qualifiedSignature: true,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
