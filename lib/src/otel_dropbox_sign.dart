// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_dropbox_sign_suppression.dart';

const _tracerName = 'dartastic_otel_libs_dropbox_sign';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class DropboxSignResult {
  const DropboxSignResult({
    this.itemCount,
    this.numPages,
    this.signatureRequestId,
    this.testMode,
    this.embedded,
    this.signerCount,
    this.signedCount,
    this.complete,
    this.declined,
    this.qualifiedSignature,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `num_pages` from page navigation.
  final int? numPages;

  /// `signature_request_id`.
  final String? signatureRequestId;

  /// `test_mode` flag — test-mode requests do not consume the
  /// signature allowance, distinct cost dim.
  final bool? testMode;

  /// True when this is an embedded signing flow (different billing
  /// SKU + redirect lifecycle).
  final bool? embedded;

  /// `signatures.length`.
  final int? signerCount;

  /// Count of signers who have signed.
  final int? signedCount;

  /// `is_complete`.
  final bool? complete;

  /// `is_declined`.
  final bool? declined;

  /// `qualified_signature` (EU eIDAS QES — billed separately, higher
  /// price tier).
  final bool? qualifiedSignature;

  /// `X-Hellosign-Trace-Id` (legacy header still used).
  final String? requestId;

  final int? statusCode;
}

class DropboxSignCallResult<T> {
  const DropboxSignCallResult({required this.value, this.result});
  final T value;
  final DropboxSignResult? result;
}

/// Wraps a Dropbox Sign API call in a CLIENT span. [operation] is one
/// of `signature_request.list`, `signature_request.get`,
/// `signature_request.send`, `signature_request.send_with_template`,
/// `signature_request.cancel`, `signature_request.remind`,
/// `signature_request.files`, `signature_request.create_embedded`,
/// `template.list`, `template.get`, `template.create_embedded_draft`,
/// `team.get`, `team.add_member`, `team.remove_member`,
/// `embedded.sign_url`, `oauth.token`.
Future<T> tracedDropboxSign<T>({
  required String operation,
  required Future<DropboxSignCallResult<T>> Function() invoke,
}) async {
  if (dropboxSignInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'dropbox_sign',
    'rpc.method': operation,
    'dropbox_sign.operation': operation,
  };

  final span = _tracer().startSpan(
    'dropbox_sign $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'dropbox_sign.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.numPages != null) {
        extras.add(OTel.attributeInt(
          'dropbox_sign.num_pages',
          r.result!.numPages!,
        ));
      }
      if (r.result!.signatureRequestId != null) {
        extras.add(OTel.attributeString(
          'dropbox_sign.signature_request.id',
          r.result!.signatureRequestId!,
        ));
      }
      if (r.result!.testMode != null) {
        extras.add(OTel.attributeBool(
          'dropbox_sign.test_mode',
          r.result!.testMode!,
        ));
      }
      if (r.result!.embedded != null) {
        extras.add(OTel.attributeBool(
          'dropbox_sign.embedded',
          r.result!.embedded!,
        ));
      }
      if (r.result!.signerCount != null) {
        extras.add(OTel.attributeInt(
          'dropbox_sign.signer_count',
          r.result!.signerCount!,
        ));
      }
      if (r.result!.signedCount != null) {
        extras.add(OTel.attributeInt(
          'dropbox_sign.signed_count',
          r.result!.signedCount!,
        ));
      }
      if (r.result!.complete != null) {
        extras.add(OTel.attributeBool(
          'dropbox_sign.complete',
          r.result!.complete!,
        ));
      }
      if (r.result!.declined != null) {
        extras.add(OTel.attributeBool(
          'dropbox_sign.declined',
          r.result!.declined!,
        ));
        if (r.result!.declined == true) {
          span.setStatus(
            SpanStatusCode.Error,
            'Dropbox Sign request declined',
          );
        }
      }
      if (r.result!.qualifiedSignature != null) {
        extras.add(OTel.attributeBool(
          'dropbox_sign.qualified_signature',
          r.result!.qualifiedSignature!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'dropbox_sign.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Dropbox Sign HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
