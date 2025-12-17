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

  UserModel({
    required this.name,
    required this.email,
    this.weight,
    this.height,
    this.goal,
  });
}
