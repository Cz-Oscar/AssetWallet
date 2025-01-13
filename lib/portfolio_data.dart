class PortfolioData {
  final DateTime date;
  final double userValue; // Wartość użytkownika
  final double marketValue; // Wartość rynkowa

  PortfolioData(this.date, this.userValue, this.marketValue);

  @override
  String toString() {
    return 'Date: $date, UserValue: $userValue, MarketValue: $marketValue';
  }
}
