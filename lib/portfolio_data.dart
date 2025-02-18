class PortfolioData {
  final DateTime date;
  final double userValue; // user value
  final double marketValue; // market value

  PortfolioData(this.date, this.userValue, this.marketValue);

  @override
  String toString() {
    return 'Date: $date, UserValue: $userValue, MarketValue: $marketValue';
  }
}
