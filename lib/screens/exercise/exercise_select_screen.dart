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
      'imagePath': 'assets/images/gorsel_3.png',
      'color': Color(0xFF9C27B0),
      'category': 'Karın',
      'difficulty': 'Zor',
    },
    {
      'name': 'Mekik',
      'description': 'Üst karın kaslarını çalıştırır.',
      'imagePath': 'assets/images/gorsel_4.png',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['Tümü', 'Güç', 'Karın', 'Bacak'];

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
                      context.router.push(
                        ExerciseSessionRoute(exerciseName: exercise['name']),
                      );
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
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.4, 0.7, 1.0],
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'BAŞLA',
                          style: TextStyle(
                            color: const Color(0xFF00C853),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFF00C853), size: 14),
                      ],
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
