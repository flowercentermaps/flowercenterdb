import '../entities/quotation.dart';

abstract interface class QuotationsRepository {
  /// Fetch all quotations visible to the current user.
  Future<List<Quotation>> getQuotations();

  /// Create a new quotation draft.
  Future<Quotation> createQuotation(Quotation quotation);

  /// Update an existing quotation.
  Future<void> updateQuotation(Quotation quotation);

  /// Delete a quotation.
  Future<void> deleteQuotation(String quotationId);
}
