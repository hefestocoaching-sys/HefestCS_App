/// Resultado de la validación del código de invitación
class ClientAccessResult {
  final String clientId;
  final String coachId;
  final String displayName;
  final String docPath;

  ClientAccessResult({
    required this.clientId,
    required this.coachId,
    required this.displayName,
    required this.docPath,
  });

  factory ClientAccessResult.fromFirestore(
    String docId,
    String docPath,
    Map<String, dynamic> data,
  ) {
    // Extraer coachId del path: coaches/{coachId}/clients/{clientId}
    final pathSegments = docPath.split('/');
    final coachId = pathSegments.length >= 2 ? pathSegments[1] : '';

    return ClientAccessResult(
      clientId: docId,
      coachId: coachId,
      displayName:
          data['fullName'] as String? ?? data['id'] as String? ?? docId,
      docPath: docPath,
    );
  }

  @override
  String toString() =>
      'ClientAccessResult(clientId: $clientId, coachId: $coachId, displayName: $displayName, docPath: $docPath)';
}
