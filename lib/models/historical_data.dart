class HistoricalData {
  final String id;
  final List<double> prices;
  final DateTime lastUpdated;

  HistoricalData(this.id, this.prices, this.lastUpdated);

  Map<String, dynamic> toJson() => {
        'id': id,
        'prices': prices,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  static HistoricalData fromJson(Map<String, dynamic> json) => HistoricalData(
        json['id'],
        List<double>.from(json['prices']),
        DateTime.parse(json['lastUpdated']),
      );
}
