import 'challenge.dart';

class MochiPoint {
  final Challenge challenge;
  final double points;
  final DateTime date;

  MochiPoint(this.challenge, this.points, this.date) {
    if (points % 0.5 != 0) {
      throw ArgumentError('Points must be a multiple of 0.5');
    }
  }
}
