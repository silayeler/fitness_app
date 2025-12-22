import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

@RoutePage()
class ExerciseSelectScreen extends StatefulWidget {
  const ExerciseSelectScreen({super.key});

  @override
  State<ExerciseSelectScreen> createState() => _ExerciseSelectScreenState();
}

class _ExerciseSelectScreenState extends State<ExerciseSelectScreen> {
  String _selectedCategory = 'Tümü';
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allExercises = const [
    {
      'name': 'Squat',
      'description': 'Bacak ve kalça kaslarını güçlendirir.',
      'imagePath': 'assets/images/gorsel_2.jpg',
      'color': Color(0xFF2196F3),
      'category': 'Bacak',
      'difficulty': 'Orta',
    },
    {
      'name': 'Plank',
      'description': 'Karın ve merkez bölgeyi kuvvetlendirir.',
      'imagePath': 'assets/images/gorsel_11.png', // New Image
      'color': Color(0xFF9C27B0),
      'category': 'Karın',
      'difficulty': 'Zor',
    },
    {
      'name': 'Mekik',
      'description': 'Üst karın kaslarını çalıştırır.',
      'imagePath': 'assets/images/gorsel_10.png', // New Image
      'color': Color(0xFFFF9800),
      'category': 'Karın',
      'difficulty': 'Kolay',
    },
    {
      'name': 'Ağırlık',
      'description': 'Genel vücut direnci ve güç artışı.',
      'imagePath': 'assets/images/gorsel_1.png', 
      'color': Color(0xFFF44336),
      'category': 'Güç',
      'difficulty': 'Zor',
    },
    {
      'name': 'Şınav',
      'description': 'Göğüs ve kol kaslarını geliştirir.',
      'imagePath': 'assets/images/gorsel_9.png', // New Image
      'color': Color(0xFF607D8B),
      'category': 'Güç',
      'difficulty': 'Orta',
    },
    {
      'name': 'Lunge',
      'description': 'Bacak ve kalça dengesini geliştirir.',
      'imagePath': 'assets/images/gorsel_5.png', // New Image
      'color': Color(0xFF4CAF50),
      'category': 'Bacak',
      'difficulty': 'Orta',
    },
    {
      'name': 'Jumping Jacks',
      'description': 'Tüm vücut kardiyo ve kondisyon.',
      'imagePath': 'assets/images/gorsel_6.png', // New Image
      'color': Color(0xFFFFC107),
      'category': 'Kardiyo',
      'difficulty': 'Kolay',
    },
    {
      'name': 'Shoulder Press',
      'description': 'Omuz ve üst vücut kuvveti.',
      'imagePath': 'assets/images/gorsel_7.png', // New Image
      'color': Color(0xFF795548),
      'category': 'Güç',
      'difficulty': 'Orta',
    },
    {
      'name': 'Glute Bridge',
      'description': 'Kalça ve bel sağlığı için.',
      'imagePath': 'assets/images/gorsel_8.png', // New Image
      'color': Color(0xFFE91E63),
      'category': 'Bacak',
      'difficulty': 'Kolay',
    },
  ];

  List<Map<String, dynamic>> get _filteredExercises {
    return _allExercises.where((exercise) {
      final name = exercise['name'].toString().toLowerCase();
      final category = exercise['category'].toString();
      final search = _searchText.toLowerCase();

      // 1. Filter by Category
      if (_selectedCategory != 'Tümü' && category != _selectedCategory) {
        return false;
      }

      // 2. Filter by Search
      if (search.isNotEmpty && !name.contains(search)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTargetDialog(BuildContext context, String exerciseName) {
    // Determine type: Time-based or Rep-based
    final isTimeBased = ['Plank', 'Glute Bridge', 'Squat'].contains(exerciseName);
    
    // Default values
    double currentValue = isTimeBased ? 30.0 : 10.0;
    double min = isTimeBased ? 10.0 : 5.0;
    double max = isTimeBased ? 180.0 : 100.0;
    int divisions = isTimeBased ? 17 : 19; // Steps of 10s or 5 reps roughly
    String label = isTimeBased ? "Süre (Saniye)" : "Tekrar Sayısı";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow it to be more flexible
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(16), // Floating effect
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SafeArea( // Prevent nav bar clash
                child: Padding(
                  padding: const EdgeInsets.all(20), // Reduced from 24
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        "$exerciseName Hedefi",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20, // Reduced from 24
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ayarlamak için kaydırın.",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12, // Reduced from 14
                        ),
                      ),
                      const SizedBox(height: 24), // Reduced from 32
                      
                      // Value Display
                      Text(
                        isTimeBased ? "${currentValue.toInt()} sn" : "${currentValue.toInt()} tekrar",
                         style: const TextStyle(
                          fontSize: 40, // Reduced from 48
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00C853),
                          letterSpacing: -1,
                        ),
                      ),
                      
                      // Slider
                      Slider(
                        value: currentValue,
                        min: min,
                        max: max,
                        divisions: (max - min) ~/ (isTimeBased ? 10 : 5), // Step size 10s or 5 reps
                        activeColor: const Color(0xFF00C853),
                        label: currentValue.toInt().toString(),
                        onChanged: (value) {
                          setModalState(() {
                            currentValue = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24), // Reduced from 32
                      
                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        height: 50, // Reduced from 56
                        child: ElevatedButton(
                          onPressed: () {
                             context.router.pop(); // Close modal
                             context.router.push(
                              ExerciseSessionRoute(
                                exerciseName: exerciseName,
                                customReps: isTimeBased ? null : currentValue.toInt(),
                                customDuration: isTimeBased ? currentValue.toInt() : null,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "BAŞLA",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['Tümü', 'Güç', 'Karın', 'Bacak', 'Kardiyo'];

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Antrenman Seç'),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Content (Search & Filters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hedefine uygun egzersizi bul.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Egzersiz ara...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filter Chips (Expanded Row)
                  Row(
                    children: categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF00C853) : theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected ? null : Border.all(color: theme.dividerColor),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF00C853).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Grid
            Expanded(
              child: _filteredExercises.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text("Sonuç bulunamadı", style: TextStyle(color: theme.disabledColor)),
                    ],
                  ),
                )
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _filteredExercises[index];
                  return _ExerciseCard(
                    name: exercise['name'] as String,
                    description: exercise['description'] as String,
                    imagePath: exercise['imagePath'] as String,
                    category: exercise['category'] as String,
                    onTap: () {
                      _showTargetDialog(context, exercise['name']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _FilterChip class removed as it is now inline for Expanded logic


class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.category,
    required this.onTap,
  });

  final String name;
  final String description;
  final String imagePath;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),

              // 2. Gradient Overlay (Bottom)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2), // Start darkening earlier
                      Colors.black.withValues(alpha: 0.8), // Stronger bottom
                      Colors.black.withValues(alpha: 0.95), // Max contrast at text level
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),

              // 3. Category Badge (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // 4. Text Content (Centered/Bottom)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                         shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                         shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    // Visual Indicator -> Arrow (replaces Play button)
                    // Visual Indicator -> Button
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20), // Pill shape
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BAŞLA',
                            style: TextStyle(
                              color: const Color(0xFF00C853), // Green Text
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF00C853), size: 14),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
