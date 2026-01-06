import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  double? weight;

  @HiveField(3)
  double? height;

  @HiveField(4)
  String? goal; // e.g., "Kilo verme"

  @HiveField(5)
  int currentXp;

  @HiveField(6)
  int currentLevel;

  @HiveField(7)
  List<String> earnedBadges;

  UserModel({
    required this.name,
    required this.email,
    this.weight,
    this.height,
    this.goal,
    this.currentXp = 0,
    this.currentLevel = 1,
    List<String>? earnedBadges,
  }) : earnedBadges = earnedBadges ?? [];
}
